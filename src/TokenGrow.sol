// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import {GetPriceFeed} from "./GetPriceFeed.sol";

contract TokenGrow is ERC20 {
    using Counters for Counters.Counter;

    Counters.Counter private _investmentCounter;
    IERC721 private _nftCollection;
    ERC20 private _paymentToken;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _nftAddr,
        address _payment
    ) ERC20(_tokenName, _tokenSymbol) {
        _nftCollection = IERC721(_nftAddr);
        _paymentToken = ERC20(_payment);
    }

    struct Investment {
        address investmentOwner;
        uint tokenId;
        uint percent;
        uint tokenAmount;
        uint tokenSold;
        uint tokenLeft;
        uint startInvestmentPeriod;
        uint endInvestmentPeriod;
        uint totalInvestors;
        uint tokenToSellLimit;
        //totalAmountPaidToInvestor
        uint totalAmount;
        // amount withdraw
        uint amountWithdraw;
        mapping(address => uint) amountInvested;
        // Token purchased by the investor
        mapping(address => uint) tokenPurchased;
    }

    mapping(uint => Investment) public investment;
    //to keep track of the total invetmentId in the contract
    uint[] public tokenIds;

    // to keep track of each investors investment Id
    mapping(address => uint[]) _myInvestmentId;

    /**
     *Each token minted is equated to 1$
     */
    function createInvestment(
        uint256 _tokenId,
        address _owner,
        uint _percent,
        uint _tokenAmount,
        uint _investmentEndTime
    ) public {
        if (msg.sender != _owner) revert();
        if (_nftCollection.balanceOf(msg.sender) < 0) revert();
        if (_nftCollection.ownerOf(_tokenId) != _owner) revert();

        uint tokenIdSave = tokenIds.length;
        _nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        Investment storage newInvestment = investment[
            _investmentCounter.current()
        ];
        newInvestment.tokenId = _tokenId;
        newInvestment.percent = _percent;
        newInvestment.tokenAmount = _tokenAmount;
        newInvestment.endInvestmentPeriod = _investmentEndTime;

        tokenIds.push(tokenIdSave);
    }

    /**
     *To display the investment registered
     */

    function getAllInvestment()
        public
        view
        returns (
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        uint length = tokenIds.length;

        // address[] memory owners = new address[](length);
        uint[] memory tokenIdsArr = new uint[](length);
        uint[] memory percents = new uint[](length);
        uint[] memory tokenAmounts = new uint[](length);
        uint[] memory tokenSolds = new uint[](length);
        uint[] memory tokenLefts = new uint[](length);
        uint[] memory startInvestmentPeriods = new uint[](length);
        uint[] memory endInvestmentPeriods = new uint[](length);

        for (uint i = 0; i < length; i++) {
            uint tokenIdSave = tokenIds[i];
            Investment storage currentInvestment = investment[tokenIdSave];

            tokenIdsArr[i] = currentInvestment.tokenId;
            percents[i] = currentInvestment.percent;
            tokenAmounts[i] = currentInvestment.tokenAmount;
            tokenSolds[i] = currentInvestment.tokenSold;
            tokenLefts[i] = currentInvestment.tokenLeft;
            startInvestmentPeriods[i] = currentInvestment.startInvestmentPeriod;
            endInvestmentPeriods[i] = currentInvestment.endInvestmentPeriod;
        }

        return (
            tokenIdsArr,
            percents,
            tokenAmounts,
            tokenSolds,
            tokenLefts,
            startInvestmentPeriods,
            endInvestmentPeriods
        );
    }

    function buyAnInvestment(
        uint _amount,
        uint _investmentId,
        address _priceFeedAddr,
        address _investor
    ) public {
        if (msg.sender != _investor) revert();
        Investment storage purchaseInvestment = investment[_investmentId];

        if (purchaseInvestment.tokenSold >= purchaseInvestment.tokenAmount)
            revert();

        int currentPrice = GetPriceFeed(_priceFeedAddr).getLatestData();

        uint amounttoPurchase = uint(currentPrice) * _amount;

        if (amounttoPurchase > purchaseInvestment.tokenLeft) revert();
        _paymentToken.transfer(address(this), amounttoPurchase);

        purchaseInvestment.amountInvested[_investor] = amounttoPurchase;
        purchaseInvestment.tokenPurchased[_investor] = _amount;
        purchaseInvestment.totalAmount += amounttoPurchase;
        _myInvestmentId[_investor].push(_investmentId);
    }

    function getYourInvestment(
        address _address
    ) public view returns (uint[] memory, uint[] memory) {
        uint[] memory investmentIds = _myInvestmentId[_address];

        uint[] memory totalAmountInvested = new uint[](investmentIds.length);
        uint[] memory totalTokenPurchased = new uint[](investmentIds.length);

        for (uint i = 0; i < investmentIds.length; i++) {
            uint investmentId = investmentIds[i];

            Investment storage investmentData = investment[investmentId];

            totalAmountInvested[i] = investmentData.amountInvested[_address];
            totalTokenPurchased[i] = investmentData.amountInvested[_address];
        }

        return (totalAmountInvested, totalTokenPurchased);
    }

    function withDrawInvestment() public {}
}