pragma solidity ^0.4.19;

// Start with Natspec comment (the three slashes)
// used for documentation - and as descriptive data for UI elements/actions

/// @title SimpleBank
/// @author nemild

/* 'contract' has similarities to 'class' in other languages (class variables,
inheritance, etc.) */
contract Bank { // CapWords
    // Declare state variables outside function, persist through life of contract

    // dictionary that maps addresses to balances
    // always be careful about overflow attacks with numbers
    mapping (address => uint) private balances;

    // "private" means that other contracts can't directly query balances
    // but data is still viewable to other parties on blockchain

    address public owner;
    // 'public' makes externally readable (not writeable) by users or contracts

    // Events - publicize actions to external listeners
    event LogDepositMade(address accountAddress, uint amount);
    struct Loan {
        address borrower;
        LoanState state;
        uint dueDate;
        uint amount;
        uint proposalCount;
        uint collected;
        uint startDate;
        bytes32 mortgage;
        mapping (uint=>uint) proposal;
    }

    Loan[] public loanList;

    mapping (address=>uint[]) public loanMap;
    // Constructor, can receive one or many variables here; only one allowed
    constructor() public payable {
        // msg provides details about the message that's sent to the contract
        // msg.sender is contract caller (address of contract creator)
        owner = msg.sender;
    }

    // This event is supposed to be identical with the one used in Coin/Token
    // interface.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Check balance of an account.
    function balanceOf(address addr) constant external returns (uint) {
        return balances[addr];
    }

    // This function is redundant, but might make some clients simplier.
    function balance() constant external returns (uint) {
        return balances[msg.sender];
    }

    // Deposit ethers to sender's account.
    function deposit() payable{
        balances[msg.sender] += msg.value;
    }

    // Withdraw ether from bank.
    // Param `to` is the Ethereum address where the ether will be send to.
    // If not provided, message sender's address will be used.
    function withdraw() payable{

        balances[msg.sender] -= msg.value;

        // Try sending ether.
        msg.sender.transfer(address(this).balance);
    }

    // This function allows batch payments using sent value and
    // sender's balance.
    // Cost: 21000 + (5000 + ~2000) * n
    function transfer(bytes32[] payments) external payable{
        uint balanceTrans = balances[msg.sender];
        uint value = msg.value + balanceTrans; // Unlikely to overflow

        for (uint i = 0; i < payments.length; ++i) {
            // A payment contains compressed data:
            // first 96 bits (12 bytes) is a value,
            // following 160 bits (20 bytes) is an address.
            bytes32 payment = payments[i];
            address addr = address(payment);
            uint v = uint(payment) / 2**160;
            if (v > value)
                break;
            balances[addr] += v;
            value -= v;
            emit Transfer(msg.sender, addr, v);
        }

        if (value != balanceTrans) {
            // Keep the rest in sender's account.
            // OPT: Looks like solidity tries to optimize storage modification
            //      as well, so it makes it worse.
            balances[msg.sender] = value;
        }
    }

    // This function is only for cost comparison with transfer() function.
    // The gain seems not to be greater than 1% so it should not be kept
    // in final version
    function transferExternalValue(bytes32[] payments) external payable{
        uint value = msg.value;

        for (uint i = 0; i < payments.length; ++i) {
            bytes32 payment = payments[i];
            address addr = address(payment);
            uint v = uint(payment) / 2**160;
            if (v > value)
                break;
            balances[addr] += v;
            value -= v;
            emit Transfer(msg.sender, addr, v);
        }

        // Send left value to sender account (conditional to safe storage
        // modification costs).
        if (value > 0)
            balances[msg.sender] += value;
    }

    // Function for record.html
    // Change if needed
    address public owner;
    
    enum ProposalState {
        WAITING,
        ACCEPTED,
        REPAID
    }

    struct Proposal {
        address lender;
        uint loanId;
        ProposalState state;
        uint rate;
        uint amount;
    }
    
    enum LoanState {
        ACCEPTING,
        LOCKED,
        SUCCESSFUL,
        FAILED
    }
    
    struct Loan {
        address borrower;
        LoanState state;
        uint dueDate;
        uint amount;
        uint proposalCount;
        uint collected;
        uint startDate;
        bytes32 mortgage;
        mapping (uint=>uint) proposal;
    }

    Loan[] public loanList;
    Proposal[] public proposalList;

    mapping (address=>uint[]) public loanMap;
    mapping (address=>uint[]) public lendMap;

    function CrowdBank() {
        owner = msg.sender;
    }

    function hasActiveLoan(address borrower) constant returns(bool) {
        uint validLoans = loanMap[borrower].length;
        if(validLoans == 0) return false;
        Loan obj = loanList[loanMap[borrower][validLoans-1]];
        if(loanList[validLoans-1].state == LoanState.ACCEPTING) return true;
        if(loanList[validLoans-1].state == LoanState.LOCKED) return true;
        return false;
    }
    
    function newLoan(uint amount, uint dueDate, bytes32 mortgage) {
        if(hasActiveLoan(msg.sender)) return;
        uint currentDate = block.timestamp;
        loanList.push(Loan(msg.sender, LoanState.ACCEPTING, dueDate, amount, 0, 0, currentDate, mortgage));
        loanMap[msg.sender].push(loanList.length-1);
    }

    function newProposal(uint loanId, uint rate) payable {
        if(loanList[loanId].borrower == 0 || loanList[loanId].state != LoanState.ACCEPTING)
            return;
        proposalList.push(Proposal(msg.sender, loanId, ProposalState.WAITING, rate, msg.value));
        lendMap[msg.sender].push(proposalList.length-1);
        loanList[loanId].proposalCount++;
        loanList[loanId].proposal[loanList[loanId].proposalCount-1] = proposalList.length-1;
    }

    function getActiveLoanId(address borrower) constant returns(uint) {
        uint numLoans = loanMap[borrower].length;
        if(numLoans == 0) return (2**64 - 1);
        uint lastLoanId = loanMap[borrower][numLoans-1];
        if(loanList[lastLoanId].state != LoanState.ACCEPTING) return (2**64 - 1);
        return lastLoanId;
    }

    function revokeMyProposal(uint id) {        
        uint proposeId = lendMap[msg.sender][id];
        if(proposalList[proposeId].state != ProposalState.WAITING) return;
        uint loanId = proposalList[proposeId].loanId;
        if(loanList[loanId].state == LoanState.ACCEPTING) {
            // Lender wishes to revoke his ETH when proposal is still WAITING
            proposalList[proposeId].state = ProposalState.REPAID;
            msg.sender.transfer(proposalList[proposeId].amount);
        }
        else if(loanList[loanId].state == LoanState.LOCKED) {
            // The loan is locked/accepting and the due date passed : transfer the mortgage
            if(loanList[loanId].dueDate < now) return;
            loanList[loanId].state = LoanState.FAILED;
            for(uint i = 0; i < loanList[loanId].proposalCount; i++) {
                uint numI = loanList[loanId].proposal[i];
                if(proposalList[numI].state == ProposalState.ACCEPTED) {
                    // transfer mortgage 
                }
            } 
        }
    }

    function lockLoan(uint loanId) {
        //contract will send money to msg.sender
        //states of proposals would be finalized, not accepted proposals would be reimbursed
        if(loanList[loanId].state == LoanState.ACCEPTING)
        {
          loanList[loanId].state = LoanState.LOCKED;
          for(uint i = 0; i < loanList[loanId].proposalCount; i++)
          {
            uint numI = loanList[loanId].proposal[i];
            if(proposalList[numI].state == ProposalState.ACCEPTED)
            {
              msg.sender.transfer(proposalList[numI].amount); //Send to borrower
            }
            else
            {
              proposalList[numI].state = ProposalState.REPAID;
              proposalList[numI].lender.transfer(proposalList[numI].amount); //Send back to lender
            }
          }
        }
        else
          return;
    }
    
    //Amount to be Repaid
    function getRepayValue(uint loanId) constant returns(uint) {
        if(loanList[loanId].state == LoanState.LOCKED)
        {
          uint time = loanList[loanId].startDate;
          uint finalamount = 0;
          for(uint i = 0; i < loanList[loanId].proposalCount; i++)
          {
            uint numI = loanList[loanId].proposal[i];
            if(proposalList[numI].state == ProposalState.ACCEPTED)
            {
              uint original = proposalList[numI].amount;
              uint rate = proposalList[numI].rate;
              uint now = block.timestamp;
              uint interest = (original*rate*(now - time))/(365*24*60*60*100);
              finalamount += interest;
              finalamount += original;
            }
          }
          return finalamount;
        }
        else
          return (2**64 -1);
    }

    function repayLoan(uint loanId) payable {
      uint now = block.timestamp;
      uint toBePaid = getRepayValue(loanId);
      uint time = loanList[loanId].startDate;
      uint paid = msg.value;
      if(paid >= toBePaid)
      {
        uint remain = paid - toBePaid;
        loanList[loanId].state = LoanState.SUCCESSFUL;
        for(uint i = 0; i < loanList[loanId].proposalCount; i++)
        {
          uint numI = loanList[loanId].proposal[i];
          if(proposalList[numI].state == ProposalState.ACCEPTED)
          {
            uint original = proposalList[numI].amount;
            uint rate = proposalList[numI].rate;
            uint interest = (original*rate*(now - time))/(365*24*60*60*100);
            uint finalamount = interest + original;
            proposalList[numI].lender.transfer(finalamount);
            proposalList[numI].state = ProposalState.REPAID;
          }
        }
        msg.sender.transfer(remain);
      }
      else
      {
        msg.sender.transfer(paid);
      }
    }
    
    function acceptProposal(uint proposeId)
    {
        uint loanId = getActiveLoanId(msg.sender); 
        if(loanId == (2**64 - 1)) return;
        Proposal pObj = proposalList[proposeId];
        if(pObj.state != ProposalState.WAITING) return;

        Loan lObj = loanList[loanId];
        if(lObj.state != LoanState.ACCEPTING) return;

        if(lObj.collected + pObj.amount <= lObj.amount)
        {
          loanList[loanId].collected += pObj.amount;
          proposalList[proposeId].state = ProposalState.ACCEPTED;
        }
    }

    function totalProposalsBy(address lender) constant returns(uint) {
        return lendMap[lender].length;
    }

    function getProposalAtPosFor(address lender, uint pos) constant returns(address, uint, ProposalState, uint, uint, uint, uint, bytes32) {
        Proposal prop = proposalList[lendMap[lender][pos]];
        return (prop.lender, prop.loanId, prop.state, prop.rate, prop.amount, loanList[prop.loanId].amount, loanList[prop.loanId].dueDate, loanList[prop.loanId].mortgage);
    }

// BORROWER ACTIONS AVAILABLE    

    function totalLoansBy(address borrower) constant returns(uint) {
        return loanMap[borrower].length;
    }

    function getLoanDetailsByAddressPosition(address borrower, uint pos) constant returns(LoanState, uint, uint, uint, uint,bytes32) {
        Loan obj = loanList[loanMap[borrower][pos]];
        return (obj.state, obj.dueDate, obj.amount, obj.collected, loanMap[borrower][pos], obj.mortgage);
    }

    function getLastLoanState(address borrower) constant returns(LoanState) {
        uint loanLength = loanMap[borrower].length;
        if(loanLength == 0)
            return LoanState.SUCCESSFUL;
        return loanList[loanMap[borrower][loanLength -1]].state;
    }

    function getLastLoanDetails(address borrower) constant returns(LoanState, uint, uint, uint, uint) {
        uint loanLength = loanMap[borrower].length;
        Loan obj = loanList[loanMap[borrower][loanLength -1]];
        return (obj.state, obj.dueDate, obj.amount, obj.proposalCount, obj.collected);
    }

    function getProposalDetailsByLoanIdPosition(uint loanId, uint numI) constant returns(ProposalState, uint, uint, uint, address) {
        Proposal obj = proposalList[loanList[loanId].proposal[numI]];
        return (obj.state, obj.rate, obj.amount, loanList[loanId].proposal[numI],obj.lender);
    }

    function numTotalLoans() constant returns(uint) {
        return loanList.length;
    }
}