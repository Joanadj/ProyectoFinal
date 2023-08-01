// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract Utilities is DSTest, StdCheats {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates an address by hashing the name, labels the address and funds it with test assets.
    function createUser(string memory name) external returns (address payable addr) {
        addr = payable(makeAddr(name));
        vm.deal({account: addr, newBalance: 1000 ether});
    }

    /// @dev Moves block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}