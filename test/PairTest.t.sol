// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";
import "../src/Pair.sol";


contract MockToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol
    ) ERC20 (
        name, 
        symbol
    ) {

    }

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }
}

contract PairTest is Test {
    
    Pair public pair;

    MockToken tokenA;
    MockToken tokenB;

    address alice = address(32312);
    address bob = address(4884848);

    function setUp() public {

        /*
            Create the mock tokens
        */
        tokenA = new MockToken("Token A", "TA");
        tokenB = new MockToken("Token B", "TB");

        /*
            Create the pair contract
        */
        pair = new Pair(
            address(tokenA),
            address(tokenB)
        );

        /*
            Deal some money to the addresses
        */
        vm.deal(alice, 10);
        vm.deal(bob, 10);

        tokenA.mint(alice, 1000);
        tokenB.mint(alice, 1000);

        
        tokenA.mint(bob, 1000);
        tokenB.mint(bob, 1000);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);

        tokenA.approve(address(pair), 5);
        tokenB.approve(address(pair), 5);

        pair.addLiquidity(
            5,
            5
        );

        assertEq(tokenA.balanceOf(address(pair)), 5);
        assertEq(tokenB.balanceOf(address(pair)), 5);
        assertEq(tokenA.balanceOf(address(alice)), 995);
        assertEq(tokenA.balanceOf(address(alice)), 995);
        assertEq(pair.balanceOf(alice), 5);
    }
    
    function testSwap() public {
        vm.startPrank(alice);

        tokenA.approve(address(pair), 5);
        tokenB.approve(address(pair), 5);

        pair.addLiquidity(
            5,
            5
        );

        vm.stopPrank();

        vm.startPrank(bob);

        uint256 balBefore = tokenA.balanceOf(bob);

        tokenB.approve(address(pair), 5);
        pair.swap(address(tokenB), 5);

        assertEq(tokenB.balanceOf(bob), 995);
        assertTrue(balBefore < tokenA.balanceOf(bob));
    }

    function testRemoveLiquidity() public {
         vm.startPrank(alice);

        tokenA.approve(address(pair), 5);
        tokenB.approve(address(pair), 5);

        pair.addLiquidity(
            5,
            5
        );

        vm.stopPrank();

        vm.startPrank(bob);


        tokenB.approve(address(pair), 5);
        pair.swap(address(tokenB), 5);

        vm.stopPrank();
        
        vm.startPrank(alice);

        uint256 shares = pair.balanceOf(alice);

        pair.removeLiquidity(shares);

        assertEq(tokenA.balanceOf(alice), 998);
        assertEq(tokenB.balanceOf(alice), 1005);
    }
}
