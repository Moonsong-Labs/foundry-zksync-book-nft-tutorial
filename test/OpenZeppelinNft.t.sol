// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/OpenZeppelinNft.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract OpenZeppelinNftTests is Test {
    using stdStorage for StdStorage;

    OpenZeppelinNft private nft;
    address private constant TEST_ADDRESS = address(65536+1); // use first non-system address

    function setUp() public {
        // Deploy NFT contract
        nft = new OpenZeppelinNft("NFT_tutorial", "TUT", "baseUri");
    }

    function testFailNoMintPricePaid() public {
        nft.mintTo(TEST_ADDRESS);
    }

    function testMintPricePaid() public {
        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
    }

    function testFailMaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(10000));
        vm.store(address(nft), loc, mockedCurrentTokenId);
        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
    }

    function testFailMintToZeroAddress() public {
        nft.mintTo{value: 0.08 ether}(address(0));
    }

    function testNewMintOwnerRegistered() public {
        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
        uint256 slotOfNewOwner = stdstore
            .target(address(nft))
            .sig(nft.ownerOf.selector)
            .with_key(1)
            .find();

        uint160 ownerOfTokenIdOne = uint160(uint256((vm.load(address(nft),bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenIdOne), TEST_ADDRESS);
    }

    function testBalanceIncremented() public { 
        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
        uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(TEST_ADDRESS)
            .find();
        
        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        nft.mintTo{value: 0.08 ether}(address(receiver));
         uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
    
    function testFailUnSafeContractReceiver() public {
        vm.etch(TEST_ADDRESS, hex"0000000000000000000000000000000000000000000000000000000000000000");
        nft.mintTo{value: 0.08 ether}(TEST_ADDRESS);
    }
}


contract Receiver is IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
}