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

contract QuorumDeploy {
  //
  // Creating new wallets
  //
  function deployNew(address bitcoinKey, address owner) returns (QuorumWallet) {
    if (msg.value < 5 finney) {
      // our fee
      throw;
    }
    
    return new QuorumWallet(bitcoinKey, owner);
  }

  //
  // Owner & fees handling
  //
  address owner;

  modifier owneronly { if (msg.sender == owner) _ }

  function setOwner(address addr) owneronly {
    owner = addr;
  }

  function QuorumDeploy() {
    owner = msg.sender;
  }
  
  function kill() owneronly {
    selfdestruct(owner);
  }
  
  function collect() owneronly {
    owner.send(this.balance);
  }
}
