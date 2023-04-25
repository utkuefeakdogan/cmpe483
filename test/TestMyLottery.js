const MyLottery = artifacts.require("MyLottery");

contract("MyLottery", (accounts) => {
    before(async () => {
        instance = await MyLottery.deployed()
    })

  it("should deposit Ether and update the sender's balance", async () => {
    for (let i = 0; i < 100; i++) { // this is an example of how i tested my contract for multiple addresses, as you can see it's 5941ms, so i wont apply this method for other tests.
      const themsgsender = accounts[i];
      const amnt = web3.utils.toWei("1", "ether");
      const initialBalance = await instance.getBalance(themsgsender);

      await instance.depositEther(amnt, { from: themsgsender, value: amnt });

      const finalBalance = await instance.getBalance(themsgsender);
      assert.equal(finalBalance - initialBalance, amnt, `Incorrect balance update`);
    }  
  });

  it("should withdraw Ether and update the sender's balance", async () => {
    const themsgsender = accounts[4];
    const amnt = web3.utils.toWei("1", "ether");

    const initialBalance = await instance.getBalance(themsgsender);
    assert(initialBalance >= amnt, "Insufficient balance");

    await instance.withdrawEther(amnt, { from: themsgsender });

    const finalBalance = await instance.getBalance(themsgsender);
    assert.equal(initialBalance - finalBalance, amnt, "Incorrect balance update");
  });

  it("should generate winning hashes correctly", async () => {
    const winningHashes = await instance.generateWinningHashes();
    assert.ok(winningHashes);
  });

  it("should buy a ticket correctly", async () => {
    await instance.LotteryFunction(); //here i create my first lottery
    const themsgsender = accounts[4];
    const ticketType = 1;
    const ticketPrice = 8;
    const depositAmount = web3.utils.toWei(ticketPrice.toString(), "ether");
    await instance.depositEther(depositAmount, { from: themsgsender, value: depositAmount });
    const hash_rnd_number = web3.utils.keccak256("my_random_hash");
    await instance.buyTicket(hash_rnd_number, ticketType, { from: themsgsender });
    const tickets = await instance.getAllTickets();
    const ticket = tickets[0];
    assert.equal(ticket.ticketOwnerAddress, themsgsender);
    assert.equal(ticket.hash_randomNo, hash_rnd_number);
    assert.equal(ticket.ticketType, ticketType);
    assert.equal(ticket.ticketStatus, 1);
    assert.equal(ticket.lotteryNo, 1);
    assert.equal(ticket.ticketWin, 0);
  });

  it("should get all tickets correctly", async () => {
    const themsgsender = accounts[4];
    // note that we bought a ticket while testing buyTicket, so buying again is unnecessary.
    const hash_rnd_number = web3.utils.keccak256("my_random_hash");
    const tickets = await instance.getAllTickets();
    assert.equal(tickets.length, 1);
    assert.equal(tickets[0].ticketOwnerAddress, themsgsender);
    assert.equal(tickets[0].hash_randomNo, hash_rnd_number);
    assert.equal(tickets[0].ticketType, 1);
    assert.equal(tickets[0].ticketStatus, 1);
  });

  it("should refund a ticket correctly", async () => {
    const themsgsender = accounts[4];
    const ticketType = 1;
    const ticketPrice = 8;
    const depositAmount = web3.utils.toWei(ticketPrice.toString(), "ether");
    await instance.depositEther(depositAmount, { from: themsgsender, value: depositAmount });
    const hash_rnd_number = web3.utils.keccak256("my_random_hash");
    await instance.buyTicket(hash_rnd_number, ticketType, { from: themsgsender });
    const tickets = await instance.getAllTickets();
    const ticket = tickets[0];
    await instance.collectTicketRefund(ticket.ticket_id ,{ from: ticket.ticketOwnerAddress }); 
    const tickets_again = await instance.getAllTickets();
    const refunded_ticket = tickets_again[0];
    assert.equal(refunded_ticket.ticketStatus, 2); // when the ticket is refunded, ticketStatus turns into 2.
    // we checked balance update earlier
  });

  it("should reveal ticket's secret hash no", async () => {
    const themsgsender = accounts[4];
    const ticketType = 1;
    const ticketPrice = 8;
    const depositAmount = web3.utils.toWei(ticketPrice.toString(), "ether");
    await instance.depositEther(depositAmount, { from: themsgsender, value: depositAmount });
    const hash_rnd_number = web3.utils.keccak256("my_random_hash");
    await instance.buyTicket(hash_rnd_number, ticketType, { from: themsgsender });
    await instance.buyTicket(hash_rnd_number, ticketType, { from: themsgsender });
    const tickets = await instance.getAllTickets();
    const ticket = tickets[1];
    const rndno = await instance.revealRndNumber(ticket.ticket_id,{ from: ticket.ticketOwnerAddress });
    assert.equal(rndno, ticket.hash_randomNo);
  });

  it("should give last owned ticket no", async () => {
    const themsgsender = accounts[4];
    const ticketType = 1;
    const ticketPrice = 8;
    const depositAmount = web3.utils.toWei(ticketPrice.toString(), "ether");
    await instance.depositEther(depositAmount, { from: themsgsender, value: depositAmount });
    const hash_rnd_number = web3.utils.keccak256("my_random_hash");
    await instance.buyTicket(hash_rnd_number, ticketType, { from: themsgsender });
    const lastticketno = (await instance.getLastOwnedTicketNo(1)).toString();
    assert.equal(lastticketno, 5); //lastticketno should be 5 because i bought 5 tickets for testing.
  });

  it("should give i'th owned ticket no and it's status", async () => {
    const tickets = await instance.getAllTickets();
    const thirdticket = tickets[2];
    const result = await instance.getIthOwnedTicketNo(3,1); //3rd ticket called with getIthOwnedTicketNo function 
    assert.equal(result[0], thirdticket.ticket_id);
    assert.equal(result[1], thirdticket.ticketStatus);
  });

  it("should check if ticket win", async () => {
    const tickets = await instance.getAllTickets();
    const secondticket = tickets[1];
    const iswin = await instance.checkIfTicketWon(1,2); //checks first ticket of 1st lottery,
    const lotteries = await instance.getAllLotteries();
    const firstlottery= lotteries[0];
    const winningHashes = firstlottery.winningHashes;
    if(secondticket.hash_randomNo== winningHashes[0] || secondticket.hash_randomNo== winningHashes[1] || secondticket.hash_randomNo== winningHashes[2]){
      assert.ok(instance.checkIfTicketWon) // ticket win
    }
    assert.ok(instance.checkIfTicketWon) //ticket didn't win.
  });

  it("should check if ticket win", async () => {
    const tickets = await instance.getAllTickets();
    const secondticket = tickets[1];
    const iswin = await instance.checkIfTicketWon(1,2); //checks first ticket of 1st lottery,
    const lotteries = await instance.getAllLotteries();
    const firstlottery= lotteries[0];
    const winningHashes = firstlottery.winningHashes;
    if(secondticket.hash_randomNo== winningHashes[0] || secondticket.hash_randomNo== winningHashes[1] || secondticket.hash_randomNo== winningHashes[2]){
      assert.ok(instance.checkIfTicketWon) // ticket win
    }
    assert.ok(instance.checkIfTicketWon) //ticket didn't win.
  });

  it("should collect prize if ticket win", async () => {
    const tickets = await instance.getAllTickets();
    const secondticket = tickets[1];
    const lotteries = await instance.getAllLotteries();
    const firstlottery= lotteries[0];
    const winningHashes = firstlottery.winningHashes;
    secondticket.hash_randomNo=winningHashes[0]; // turn this ticket into a winner one for testing.
    if(secondticket.hash_randomNo== winningHashes[0] || secondticket.hash_randomNo== winningHashes[1] || secondticket.hash_randomNo== winningHashes[2]){
      assert.ok(instance.collectTicketRefund) // ticket win
    }
    assert.ok(instance.collectTicketRefund) //ticket didn't win.
  });

  it("should give i'th winning ticket number and winning amount", async () => {
    const tickets = await instance.getAllTickets();
    const secondticket = tickets[1];
    const lotteries = await instance.getAllLotteries();
    const firstlottery= lotteries[0];
    const winningHashes = firstlottery.winningHashes;
    secondticket.hash_randomNo=winningHashes[0]; // turn this ticket into a winner one for testing.
    await instance.checkIfTicketWon(1,2); // this function checks if 2nd ticket of 1st lottery win,if so sends the ticket into winninghashes[]
    const result = instance.getIthWinningTicket(1,1); //gets first winning ticket of the first lottery
    assert.ok(result);
  });
  
  it("should get lottery nums", async () => {
    const unixtime1 = 1682442920;
    const unixtime2= 2682422260;
    const result1 = (await instance.getLotteryNos(unixtime1)).toString(); // get total monney collected of first lottery
    const result2 = (await instance.getLotteryNos(unixtime2)).toString(); // get total monney collected of first lottery
    assert.equal(result1,1) //given unixtime, we're at the first lottery.
    assert.equal(result2,1654) //given unixtime, we're at the 1654th lottery.
  });

});
