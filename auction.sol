// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Auction {
    address private owner;
    uint256 private startTime;
    uint256 private stopTime;
    bool private auctionEnded = false;

    struct Bid {
        address bider;
        uint256 value;
        uint256 bidTime;
    }

    Bid[] private offers; // History of all bids placed
    Bid private winner; // The final winning bid
    mapping(address => Bid[]) private bidsByBider; // Bid history for each bidder
    mapping(address => uint256) private pendingWithdrawals;

    constructor () {
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + 7 days; // 7-day auction initially
    }

    // --- Events ---
    event NewOffer(address indexed bider, uint256 amount, uint256 bidTime);
    event AuctionEnded(address indexed winnerAddress, uint256 winnerValue);
    event FundsWithdrawn(address indexed bider, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(owner == msg.sender, "Solo el propietario puede ejecutar esto.");
        _;
    }

    modifier isActiveCheck() {
        require(isActive(), "La subasta ya no esta activa.");
        _;
    }

    modifier isNotActiveCheck() {
        require(!isActive(), "La subasta aun esta activa.");
        _;
    }

    // Validates the bid based on whether it is the first or subsequent bid
    modifier isValidBid() {
        if (offers.length == 0) {
            require(msg.value >= 1 ether, "La oferta inicial minima es 1 Ether.");
        } else {
            require(msg.value >= (offers[offers.length - 1].value * 105) / 100, "No fue aceptada la oferta, el monto es muy bajo (min. 5% mas que la anterior).");
        }
        _;
    }

    // --- Internal/View Functions (Helpers) ---

    function isActive() internal view returns (bool) {
        return block.timestamp < stopTime && !auctionEnded;
    }

    function withdrawFundsForInternalUseOnly(bool _commission, address _currentAcount) internal {
        uint256 amount = pendingWithdrawals[_currentAcount];
        bool transactionFlag;

        if (_commission) {
            if (amount > 0) {
                // Cobra una comision del 2%
                amount -= (amount * 2) / 100;
                transactionFlag = true;
            }
        } else {
            require(amount > 0, "No tienes fondos pendientes para retirar.");
            transactionFlag = true;
        }

        if (transactionFlag) {
            pendingWithdrawals[_currentAcount] = 0; // Resetear el monto antes de la transferencia para evitar re-entrancy

            (bool success, ) = payable(_currentAcount).call{value: amount}("");
            require(success, "Fallo al enviar Ether de vuelta.");

            emit FundsWithdrawn(_currentAcount, amount);
        }

    }

    // --- Main Functions ---

    // Function to place a bid
    function addOffer() external payable isActiveCheck isValidBid {
        // The current bid becomes the new highest bid (for now)
        // Save the previous bid for possible refund
        if (winner.bider != address(0)) { // Si ya hay una oferta "ganadora"
            // Adds to pending funds for withdrawal for the previous bidder
            // This assumes that winner is always the bid to beat.
            pendingWithdrawals[winner.bider] += winner.value;
        }

        Bid memory newBid = Bid({
            bider: msg.sender,
            value: msg.value,
            bidTime: block.timestamp
        });

        offers.push(newBid); // Add to global bid history
        bidsByBider[msg.sender].push(newBid); // Add to bidder's bid history

        winner = newBid; // Update the provisional 'winner'
        stopTime += 10 minutes; // Extends the auction by 10 minutes
        
        emit NewOffer(msg.sender, msg.value, block.timestamp);
    }

    // Function to end the auction and determine the winner
    function endAuction() external onlyOwner isNotActiveCheck {
        require(!auctionEnded, "La subasta ya ha finalizado."); // Prevent calling multiple times

        auctionEnded = true; // Mark the auction as permanently ended

        // Logic for the winner (if no bids, winner.bider will be address(0))
        if (offers.length > 0) {
            // If there's a winner (i.e., there was at least one valid bid)
            if (winner.bider != address(0)) {
                // The winner's value remains in the contract.
                // The rest of the Ether from the losers is refunded.
                for (uint i = 0; i < offers.length; i++) { 
                    withdrawFundsForInternalUseOnly(true, offers[i].bider);
                }
            }
        }
        emit AuctionEnded(winner.bider, winner.value);
    }


    // Allows participants to withdraw funds from their previous bids
    function withdrawFunds() external {
        withdrawFundsForInternalUseOnly(false, msg.sender);
    }


    // --- Getters ---

    // Return the winning bid and its details
    function showWinner() external view returns(Bid memory) {
        require(auctionEnded && winner.bider != address(0), "El ganador aun no ha sido determinado o la subasta no ha terminado.");
        return winner;
    }

    // Return all bids placed
    function showAllOffers() external view returns (Bid[] memory) {
        return offers;
    }

    // Return bids by a specific bidder
    function showBidsByBider(address _bider) external view returns (Bid[] memory) {
        return bidsByBider[_bider];
    }

    // Get the owner
    function getOwner() external view returns (address) {
        return owner;
    }

    // Get the stop time
    function getStopTime() external view returns (uint256) {
        return stopTime;
    }

    // Get pending funds for a user
    function getPendingWithdrawal(address _bider) external view returns (uint256) {
        return pendingWithdrawals[_bider];
    }


    // Function to withdraw all Ether from the contract
    function withdrawContractBalanceToOwner() external onlyOwner isNotActiveCheck{
        // Total contract balance
        uint256 contractBalance = address(this).balance;

        // Ensure there's Ether to send
        require(contractBalance > 0, "No hay Ether en el contrato para retirar.");

        // Perform the transfer to the owner
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Fallo al enviar el balance del contrato al propietario.");

        emit FundsWithdrawn(owner, contractBalance); 
    }

    // Emergency stop
    function emergencyStop() external onlyOwner isActiveCheck {
        stopTime = block.timestamp;
    }

    // Function to receive Ether directly without calling a specific function
    receive() external payable {
        // This is useful if someone accidentally sends Ether to the contract without calling addOffer
        // or if a contract sends Ether without specifying a function.
    }

    //  Fallback function for calls to non-existent functions or calls without data
    fallback() external payable {
    }
}