// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Aragon contract for governance token with proposal and voting functionality 0x40Bf4Cdc38a715f812E932Bb83FD9bC0d8a32904
contract AirBender {
    // Token constants
    string public constant NAME = "Air Bender";
    string public constant SYMBOL = "AIR";
    uint8 public constant DECIMALS = 18;

    // State variables
    uint256 public totalSupply;
    address public immutable owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Struct for storing proposal details
    struct Proposal {
        address proposer;
        uint256 endTime;
        bool executed;
        uint256 voteCount;
        uint256 positiveVotes; // Bitmap for positive votes
    }

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(uint256 indexed proposalId, uint256 endTime);
    event Voted(uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    // Constructor sets total supply and owner's balance
    constructor() {
        owner = msg.sender;
        totalSupply = 10000000 * (10 ** uint256(DECIMALS));
        balances[owner] = totalSupply;
    }

    // Modifier to restrict function access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    // Transfer function for token transfer
    function transfer(address recipient, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        _transfer(msg.sender, recipient, amount);
    }

    // Internal transfer function handling the transfer logic
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Transfer to the zero address");
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Approve function to allow another address to spend tokens
    function approve(address spender, uint256 amount) public returns (bool) {
        _approveInternal(msg.sender, spender, amount);
        return true;
    }

    // Internal function handling approval logic
    function _approveInternal(address ownerAddr, address spender, uint256 amount) internal {
        require(spender != address(0), "Approve to the zero address");
        allowed[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    // TransferFrom function to transfer tokens on behalf of another address
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowed[from][msg.sender], "Insufficient allowance");
        _transfer(from, to, amount);
        _approveInternal(from, msg.sender, allowed[from][msg.sender] - amount);
        return true;
    }

    // Increase total supply of the tokens
    function increaseSupply(uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    // Decrease total supply of the tokens
    function decreaseSupply(uint256 amount) public onlyOwner {
        require(balances[owner] >= amount, "Insufficient balance to decrease supply.");
        totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(owner, address(0), amount);
    }

    // Create a new proposal for governance
    function createProposal(uint256 duration) public {
        require(balances[msg.sender] > 0, "Only token holders can create proposals");
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.proposer = msg.sender;
        newProposal.endTime = block.timestamp + duration;
        newProposal.executed = false;
        newProposal.positiveVotes = 0;
        emit ProposalCreated(nextProposalId, newProposal.endTime);
        nextProposalId++;
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool userVote) public {
        require(balances[msg.sender] > 0, "Only token holders can vote");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        uint256 voterIndex = uint256(uint160(msg.sender)) % 256;
        uint256 currentVote = (proposal.positiveVotes >> voterIndex) & 1;
        require(currentVote == 0, "Voter has already voted");
        if (userVote) {
            proposal.voteCount++;
            proposal.positiveVotes |= (1 << voterIndex);
        }
        emit Voted(proposalId, userVote);
    }

    // Execute a proposal after voting period ends
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period has not yet ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > totalSupply / 2, "Majority vote has not reached");
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
