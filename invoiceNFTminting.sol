// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    //function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256);
}

// interface IERC721{
//         function balanceOf(address owner) external view returns (uint256 balance);
//         function ownerOf(uint256 tokenId) external view returns (address owner);
//         function safeTransferFrom(address from, address to, uint256 tokenId) external;
// }

contract NFTContract is ERC721URIStorage, Ownable {
    uint256 tokenId;
    IERC20 public token;
    constructor(address _token) ERC721("PBMCNFT", "PBMN") {
        token = IERC20(_token);
    }

    struct NftDetails {
        address owner;
        address seller;
        uint256 price;
        uint256 tokens;
        bool isSold;
        bool isBurn;
    }

    struct Investor {
        uint256 deposit;
        uint256 withdraw;
    }

    mapping(uint256 => NftDetails) public tokenIdToNftDetails;
    mapping(address => bool) public isAdmin;
    mapping(address => uint) public buyersDetail;
    mapping(address => Investor) public investorsDetail;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "only admins are allowed");
        _;
    }

    function mint(string memory _tokenURI) external onlyAdmin {
        tokenId++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    //suplier
    function depositCollateral(
        address seller,
        uint256 _tokenId,
        uint256 pbmcAmount,
        uint256 NFTPrice
    ) external onlyAdmin {
        require(NFTPrice >0 ,"nft value can not be zero");
        token.transferFrom(msg.sender, address(this), pbmcAmount);
        tokenIdToNftDetails[_tokenId] = NftDetails(
            msg.sender,
            seller,
            NFTPrice,
            pbmcAmount,
            false,
            false
        );
    }

    function sendTokenByBuyer(uint256 pbmcAmount) external {
        token.transferFrom(msg.sender, address(this), pbmcAmount);
        buyersDetail[msg.sender] +=pbmcAmount;
    }

    function investorDeposit(uint256 _tokenId) external {
        NftDetails storage nftDetails = tokenIdToNftDetails[_tokenId];
        require(nftDetails.isSold ==false, "nft is already sold");
        require(nftDetails.price > 0, "wrong token id");
        token.transferFrom(msg.sender, address(this), nftDetails.price);
        nftDetails.owner = msg.sender;
        nftDetails.isSold = true;
        investorsDetail[msg.sender].deposit += nftDetails.price;
    }

    function investorWithdraw(uint256 pbmcAmount, address _investorAddress)
        external
        onlyAdmin
    {
        token.transfer(_investorAddress, pbmcAmount);
        investorsDetail[_investorAddress].withdraw += pbmcAmount;
    }

    function burnNft(uint256 _tokenId) external onlyAdmin {
        NftDetails storage nftDetails = tokenIdToNftDetails[_tokenId];
        require(nftDetails.isSold ==false, "nft is already sold");
        tokenIdToNftDetails[_tokenId].isBurn = true;
        _burn(_tokenId);
    }

    function addAdmin(address _address) external onlyOwner {
        isAdmin[_address] = true;
    }

    function removeAdmin(address _address) external {
        isAdmin[_address] = false;
    }
}
