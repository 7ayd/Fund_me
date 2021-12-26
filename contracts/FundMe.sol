//SPDX-License-Identifier: MIT;

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // whatever is added here is immediately executed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // "Payable" this means this function can be used to pay for things
    function fund() public payable {
        // $50
        uint256 minUSD = 20 * 10**10;
        require(
            getConversionRate(msg.value) >= minUSD,
            "You need to spend more eth"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        // what the Eth -> USD conversion rate
        funders.push(msg.sender);
    }

    // This is making a contract call to a different conract from Chainlink
    function getVerison() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
        // 4,326.65000000 this has 8 decimals
    }

    // We want to convert Wei to USD. 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        //0.00000432665000000
    }

    function getEntranceFee() public view returns (uint256) {
        // min USD
        uint256 mimimumUSD = 50 * 10**10;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // keyword this is talking about the contract you currently are in
    // transfer sends some eth to another address
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
