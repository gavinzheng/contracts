/*
 * Quorum Wallet contract
 * Copyright (C) 2016 Alex Beregszaszi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

contract QuorumWallet {
  address public bitcoinKey;
  address owner;

  struct Transaction {
      address to;
      uint value;
      bytes data;
  }
  
  mapping (bytes32 => Transaction) public pending;

  bytes32[] public pendingRefs;
  
  // Helper to reduce number of calls
  function allPendingRefs() returns (bytes32[]) {
      return pendingRefs;
  }

  function QuorumWallet(address _bitcoinKey, address _owner) {
      bitcoinKey = _bitcoinKey;
      owner = _owner;
  }

  function quorumVersion() constant returns (uint) {
      return 1;
  }

  // fallback to receive money
  function () {
  }

  function createTransfer(address to, uint value, bytes data) returns (bytes32) {
      // TODO: use block.blockhash(0) ?
      bytes32 ref = sha3(block.number, now, to, value, data);

      Transaction memory tx;
      tx.to = to;
      tx.value = value;
      tx.data = data;

      pending[ref] = tx;
      pendingRefs.push(ref);

      return ref;
  }

  function signBitcoin(bytes32 ref, uint8 v, bytes32 r, bytes32 s) {
      Transaction tx = pending[ref];
      checkTx(tx);

      bytes32 bsmHash = createBSMHash(bytes32ToHexString(ref));

      if (ecrecover(bsmHash, v, r, s) != bitcoinKey) {
          // Signed with a different key
          throw;
      }

      executeTransfer(tx, ref);
  }

  function signEthereum(bytes32 ref) {
      if (owner == 0 || msg.sender != owner) {
          // Not an owner
          throw;
      }

      Transaction tx = pending[ref];
      checkTx(tx);
      executeTransfer(tx, ref);
  }

  function kill() {
      if (owner == 0 || msg.sender != owner) {
          throw;
      }
      selfdestruct(owner);
  }

  function checkTx(Transaction tx) internal {
    // Invalid ref
    if (tx.to == 0 && tx.value == 0 && tx.data.length == 0)
      throw;
  }

  function executeTransfer(Transaction tx, bytes32 ref) internal {
    if (tx.data.length > 0) {
      // NOTE: this looks horribly complex, but it is only:
      // basic call: <address>.call(<method/data>)
      // extended with value: <address>.call.value(<value>)(<method/data>)
      // More at https://github.com/ethereum/wiki/wiki/Solidity-Features#generic-call-method
      tx.to.call.value(tx.value)(tx.data);
    } else {
      tx.to.send(tx.value);
    }

    delete pending[ref];
    for (var i = 0; i < pendingRefs.length; i++) {
      if (pendingRefs[i] == ref)
        delete pendingRefs[i];
    }
  }

  // Notes:
  // - this is limited to a payload length of 253 bytes
  // - the payload should be ASCII as many clients will want to display this to the user
  function createBSMHash(string payload) internal returns (bytes32) {
    // \x18Bitcoin Signed Message:\n#{message.size.chr}#{message}
    string memory prefix = "\x18Bitcoin Signed Message:\n";
    return sha256(sha256(prefix, bytes1(bytes(payload).length), payload));
  }

  function nibbleToChar(uint nibble) internal returns (uint) {
    nibble &= 0x0f;
    if (nibble > 9)
      return nibble + 87; // nibble + 'a'- 10
    else
      return nibble + 48; // '0'
  }

  function bytes32ToHexString(bytes32 input) internal returns (string) {
    bytes memory ret = new bytes(64);

    uint j = 0;
    for (uint i = 0; i < 32; i++) {
        uint tmp = uint(input[i]);
        ret[j++] = byte(nibbleToChar(tmp / 0x10));
        ret[j++] = byte(nibbleToChar(tmp));
    }

    return string(ret);
  }
}
