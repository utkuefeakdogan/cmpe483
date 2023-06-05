pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

contract MyLottery {
    address owner = address(0x0C63C76c610e2ebBE99385c339Adb18d303B8828); // this is my metamask address,
    uint256 deployTime = 1682592095; // current block.timestamp ;
    
    function getOwner() public view returns(address){  //check the owner
        return owner;
    }

    modifier onlyOwner() { //validation for the owner
    require(msg.sender == owner, "Only owner can use this function");
    _;
    }
    
    struct Ticket {
        address ticketOwnerAddress;
        bytes32 hash_randomNo;
        uint256 ticket_id;
        uint256 ticketType;
        uint256 ticketStatus;
        uint256 lotteryNo;
        uint256 ticketWin;
    }

    struct Lottery {
        uint256 lottery_id;
        bytes32[] winningHashes;
        uint256 winningId;
        uint256 prizePoolofLottery;
    }

    mapping(uint256 => Ticket) private tickets; // Under tickets, we have Ticket typed objects.
    mapping(uint256 => Ticket) private ticketsForSpesificLotery; 
    mapping(uint256 => Ticket) private winningTickets;
    mapping(uint256 => Lottery) private lotteries;
    uint256 public currentLotteryNo = 0;
    uint256 totalticketno = 0;
    uint256 totalwinningticketno = 0;
    uint256 private prizePool;
    mapping(address => uint256) private balances;

    function depositEther(uint amnt) public payable{
        require(msg.value == amnt, "Message value must be equal to amount.");
        balances[msg.sender] += amnt;
    }

    // notice that withdraw function doesnt work for the owner because we withdraw from the contract's balance, 
    // which is the owner's balance, so owner cant withdraw from his/herself
    function withdrawEther(uint amnt) public {
        require(balances[msg.sender] >= amnt, "Bruh.");
        balances[msg.sender] -= amnt;
    }

    // test function
    function getBalance(address _address) public view onlyOwner returns (uint) {
        return balances[_address];
    }

    //this function is for testing
    function generateRandomHash() public view returns (bytes32) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        bytes32 randomHash = bytes32(randomNumber);
        return randomHash;
    }

    function generateWinningHashes() private view returns (bytes32[3] memory) {
        bytes32[3] memory winningHashes;
        for (uint256 i = 0; i < 3; i++) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)));
            winningHashes[i] = bytes32(randomNumber);
        }
        return winningHashes;
    }

    // After presentation, change winning conditions
    function generateWinnerId() public view returns (uint256) {
        uint upperBound = totalticketno;
        uint256 lowerBound = 0;
        if(currentLotteryNo!=1){
            for (uint256 j = 0; j < totalticketno; j++) {
                Ticket memory ticket = tickets[j];
                  if (ticket.lotteryNo-1 == currentLotteryNo-1) {
                       lowerBound++;
                    }
                }
        }

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (upperBound - lowerBound + 1);
        return randomNumber + lowerBound+1;
    }
    

    //we will call this function via frontEnd every week, it will autonomously run the lottery.
    function LotteryFunction() public onlyOwner {
        //require((deployTime - block.timestamp) - currentLotteryNo*(1 weeks)) < 0, "other lottery is running") commented
        // for test reasons
        Lottery storage added_lottery = lotteries[currentLotteryNo];
        added_lottery.lottery_id = currentLotteryNo;
        added_lottery.winningHashes = generateWinningHashes();
        added_lottery.prizePoolofLottery = prizePool;
        added_lottery.winningId= generateWinnerId();
        currentLotteryNo++;  
    }


    //buy a ticket with your generated random hash
    function buyTicket(bytes32 hash_rnd_number, uint256 ticketType) public payable {
        require(ticketType == 1 || ticketType == 2 || ticketType == 3 , "There are 3 types of tickets: 1 -> full, 2 -> half, 3 -> quarter");
        Lottery storage lottery = lotteries[currentLotteryNo-1];
        if (ticketType == 1) {
            balances[msg.sender] -= 8;
            prizePool +=8;
            lottery.prizePoolofLottery+=8;
        } else if (ticketType == 2) {
            balances[msg.sender] -= 4;
            prizePool +=4;
            lottery.prizePoolofLottery+=8;
        } else if (ticketType == 3) {
            balances[msg.sender] -= 2;
            prizePool +=2;
            lottery.prizePoolofLottery+=2;
        } else {
            revert("You don't have enough balance");
        }
  
        Ticket storage added_ticket = tickets[totalticketno];
        added_ticket.ticketOwnerAddress=address(msg.sender);
        added_ticket.hash_randomNo=hash_rnd_number;
        added_ticket.ticket_id = totalticketno + 1;
        added_ticket.ticketType = ticketType;
        added_ticket.ticketStatus = 1; // 1 is active , 2 has been refunded
        added_ticket.lotteryNo = currentLotteryNo;
        added_ticket.ticketWin = 0;
        totalticketno = totalticketno +1;
        
    }

    //a function for checking allTickets, remember this is onlyOwner.
    function getAllTickets() public view onlyOwner returns(Ticket[] memory result) {
        result = new Ticket[](totalticketno);
        for (uint i = 0; i < totalticketno; i++) {
            result[i] = tickets[i];
        }      
    }

    function getAllLotteries() public view onlyOwner returns(Lottery[] memory result) {
        result = new Lottery[](currentLotteryNo);
        for (uint i = 0; i < currentLotteryNo; i++) {
            result[i] = lotteries[i];
        }
    }

    function collectTicketRefund(uint ticket_no) public {
        Ticket storage ticket = tickets[uint256(ticket_no-1)];
        require(msg.sender == ticket.ticketOwnerAddress, "Only the ticket owner can collect the refund.");
        require(ticket.ticketStatus == 1, "Ticket has already refunded.");
        require(ticket_no <= totalticketno, "There is not enough tickets yet :D");

        uint refundAmount;
        if (ticket.ticketType == 1) {
            refundAmount = 8;
        } else if (ticket.ticketType == 2) {
            refundAmount = 4;
        } else if (ticket.ticketType == 3) {
            refundAmount = 2;
        }
        balances[ticket.ticketOwnerAddress] += refundAmount;
        ticket.ticketStatus = 2; // Ticket has refunded
    }

    //I didn't understand why we take uint rnd_no in this function, so i removed it.
    function revealRndNumber(uint256 ticketno) public view returns(bytes32 rndno) {
        Ticket storage ticket = tickets[uint256(ticketno-1)];
        require(msg.sender == ticket.ticketOwnerAddress, "Only the ticket owner can reveal the number");
        require(ticket.ticketStatus == 1, "Ticket is not active");
        require(ticketno < totalticketno, "There is not enough tickets yet :D");
        return ticket.hash_randomNo;
    }


    function getLastOwnedTicketNo(uint256 lottery_no) public view returns (uint256) {
        require(lottery_no <= currentLotteryNo, "Invalid lottery number");
        for (int256 i = int256(totalticketno) - 1; i >= 0; i--) {
            Ticket memory ticket = tickets[uint256(i)];
            if (ticket.lotteryNo == lottery_no) {
                return ticket.ticket_id;
            }
        }
        
        return 0; // If no ticket is found for the lottery, return 0
    }


    // this doesnt returns ith "owned" ticketno, returns i'th ticket of spesific lotteryno
    // can be adjustable for a spesific msg.sender easily, but i think this is more necessary.
    function getIthOwnedTicketNo(uint256 i, uint256 lottery_no) public view returns (uint256 ticketno, uint256 status) {
        uint256 ticketNoOfSpecificLottery = 0;
        for (uint256 j = 0; j < totalticketno; j++) {
            Ticket memory ticket = tickets[j];
            if (ticket.lotteryNo == lottery_no) {
                ticketNoOfSpecificLottery++;
            }
        }

    require(i < ticketNoOfSpecificLottery+1, "Invalid index");

    Ticket[] memory allTicketsofspecificlottery = new Ticket[](ticketNoOfSpecificLottery);
    uint256 x = 0;

    for (uint256 j = 0; j < totalticketno; j++) {
        Ticket memory ticket = tickets[j];
        if (ticket.lotteryNo == lottery_no) {
            allTicketsofspecificlottery[x] = ticket;
            x++;
        }
    }

    return (allTicketsofspecificlottery[i-1].ticket_id, allTicketsofspecificlottery[i-1].ticketStatus);
}


    //returns the amount which ticket has won
    function checkIfTicketWon(uint lottery_no, uint ticket_no) public returns (bool mybool) {
        Lottery storage winningLottery = lotteries[lottery_no-1];
        Ticket storage ticket = tickets[ticket_no-1];
        // if(ticket.hash_randomNo == winningLottery.winningHashes[0] || ticket.hash_randomNo == winningLottery.winningHashes[1] || ticket.hash_randomNo == winningLottery.winningHashes[2]){
        //    amount=ticket.ticketWin;
        //}
        if(ticket.ticket_id==winningLottery.winningId){
            ticket.ticketWin=prizePool;
        }
        
        if(ticket.ticket_id==winningLottery.winningId){
            mybool= true;
        }
        
        require(ticket.ticketStatus == 1, "Ticket has already refunded.");
        winningTickets[totalwinningticketno] = ticket;
        totalwinningticketno++;
        
    }


    function collectTicketPrize(uint lottery_no, uint ticket_no) public {
        //require(((deployTime - block.timestamp) - currentLotteryNo*(1 weeks)) < 0); commented for testing
        Lottery storage winningLottery = lotteries[lottery_no-1];
        Ticket storage ticket = tickets[ticket_no-1];
        require(ticket.ticketStatus == 1, "Ticket has already refunded.");
        require(ticket.ticketWin!=0,"Ticket didn't win.");
        //require(ticket.hash_randomNo == winningLottery.winningHashes[1] || ticket.hash_randomNo == winningLottery.winningHashes[2] || ticket.hash_randomNo == winningLottery.winningHashes[3], "Ticket didn't win");
                if (ticket.ticketType == 1) {
                    balances[ticket.ticketOwnerAddress] += winningLottery.prizePoolofLottery;
                    prizePool = prizePool - winningLottery.prizePoolofLottery/2;
                } else if (ticket.ticketType == 2) {
                    balances[ticket.ticketOwnerAddress] += winningLottery.prizePoolofLottery/2;
                    prizePool = prizePool - winningLottery.prizePoolofLottery/4;
                } else if (ticket.ticketType == 3) {
                    balances[ticket.ticketOwnerAddress] += winningLottery.prizePoolofLottery/4;
                    prizePool = prizePool - winningLottery.prizePoolofLottery/8;
                }
    }

    function getIthWinningTicket(uint i, uint lottery_no) public view returns (uint256 ticket_no,uint amount) {
        uint256 winningTicketNoOfSpecificLottery=0;
        for (int256 j = int256(totalwinningticketno) - 1; j >= 0; j--) {
            Ticket memory ticket = winningTickets[uint256(j)];
            if (ticket.lotteryNo == lottery_no) {
                winningTicketNoOfSpecificLottery++;
            }
        }
        
        Ticket[] memory allWinningTicketsofspecificlottery;
        allWinningTicketsofspecificlottery = new Ticket[](winningTicketNoOfSpecificLottery);
        uint256 x = 1;

        for (uint256 j = 0 ; j<= totalwinningticketno ; j++) {
            Ticket memory ticket = winningTickets[uint256(j)];
            if (ticket.lotteryNo == lottery_no) {
                allWinningTicketsofspecificlottery[x] = ticket;
                x++;
            }
        }

        return(allWinningTicketsofspecificlottery[i].ticket_id,allWinningTicketsofspecificlottery[i].ticketWin);
    }

    function getLotteryNos(uint256 unixtimeinweek) public view returns (uint256 lottery_no) {
        require(unixtimeinweek>deployTime, "At the time you entered, this smart contract wasn't here.");
        lottery_no = ((unixtimeinweek - deployTime) / 604800)+1;
    }

    function getTotalLotteryMoneyCollected(uint lottery_no) public view returns (uint256 amount) {
        uint256 ticketNoOfSpecificLottery=0;
        for (int256 j = int256(totalticketno) - 1; j >= 0; j--) {
            Ticket memory ticket = tickets[uint256(j)];
            if (ticket.lotteryNo == lottery_no) {
                ticketNoOfSpecificLottery++;
            }
        }

        for (uint256 j = 0 ; j< totalticketno ; j++) {
            Ticket memory ticket = tickets[uint256(j)];
            if (ticket.lotteryNo == lottery_no) {
                if (ticket.ticketType == 1 && ticket.ticketStatus ==1) {
                    amount += 8;
                } else if (ticket.ticketType == 2 && ticket.ticketStatus ==1) {
                    amount += 4;
                } else if (ticket.ticketType == 3 && ticket.ticketStatus ==1) {
                    amount += 2;
                }
            }
        }
    }
}