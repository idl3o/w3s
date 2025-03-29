// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StreamToken is ERC20, Ownable {
    struct Stream {
        address recipient;
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    struct Wager {
        address participant1;
        address participant2;
        uint256 amount;
        address winner; // Address of the winner, set when resolved
        bool resolved;
    }

    struct DAO {
        string name;
        address daoAddress;
        string metadata;
    }

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    struct Document {
        string title;
        string contentHash; // Hash of the document content (e.g., IPFS hash)
        string metadata;
        address uploader;
    }

    struct FundingPool {
        address creator;
        uint256 totalFunds;
        string metadata;
    }

    struct Service {
        string name;
        string description;
        address serviceAddress;
        bool active;
    }

    mapping(uint256 => Stream) public streams;
    uint256 public nextStreamId;

    mapping(uint256 => Wager) public wagers;
    uint256 public nextWagerId;

    mapping(address => bool) public blockedAddresses;

    mapping(uint256 => string) private streamCitations;
    mapping(uint256 => string) private wagerCitations;

    mapping(uint256 => DAO) public daos;
    uint256 public nextDaoId;

    mapping(address => Stake) public stakes;
    uint256 public rewardRatePerSecond; // Reward rate in tokens per second

    mapping(uint256 => Document) public documents;
    uint256 public nextDocumentId;

    mapping(uint256 => FundingPool) public fundingPools;
    uint256 public nextFundingPoolId;

    mapping(uint256 => Service) public services;
    uint256 public nextServiceId;

    // NFT related variables
    mapping(uint256 => address) private _nftOwners;
    mapping(address => uint256) private _nftBalances;
    mapping(uint256 => string) private _nftTokenURIs;
    uint256 public nextNftId;

    // NFT events
    event NftMinted(address indexed to, uint256 tokenId, string tokenURI);
    event NftTransferred(address indexed from, address indexed to, uint256 tokenId);

    // Safe Processing variables
    mapping(address => bool) public approvedProcessors;
    mapping(bytes32 => bool) public processedTransactions;
    mapping(uint256 => bool) public executedOperations;

    // Discovery variables
    mapping(address => uint256[]) public userStreams;
    mapping(address => uint256[]) public userWagers;
    mapping(address => uint256[]) public userDocuments;
    mapping(address => uint256[]) public userFundingPools;

    // Events for discovery
    event EntityCreated(string entityType, uint256 entityId, address creator);
    event EntityUpdated(string entityType, uint256 entityId, address updater);

    // --- New Security Features ---
    mapping(address => bool) public trustedOperators;
    mapping(address => mapping(address => bool)) public delegateApprovals;
    bool public emergencyPause;

    // --- Token Enhancements ---
    struct TokenConfig {
        uint256 maxSupply;
        uint256 burnRate;
        uint256 transferTaxRate;
    }

    TokenConfig public tokenConfig;
    uint256 public totalBurned;

    // --- Escrow Variables ---
    struct Escrow {
        address depositor;
        address recipient;
        uint256 amount;
        uint256 releaseTime;
        bool released;
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public nextEscrowId;

    // --- Notification System ---
    event Notification(address indexed user, string notificationType, string message);
    mapping(address => string[]) private userNotifications;
    mapping(address => bool) public notificationsEnabled;

    // --- Delegation System ---
    struct Delegation {
        address delegator;
        address delegate;
        bool canTransfer;
        bool canManage;
        bool canClaim;
    }

    mapping(uint256 => Delegation) public delegations;
    uint256 public nextDelegationId;

    // --- Events ---
    event SecurityStateChanged(bool isPaused);
    event EscrowCreated(uint256 escrowId, address depositor, address recipient, uint256 amount);
    event EscrowReleased(uint256 escrowId);
    event DelegationCreated(uint256 delegationId, address delegator, address delegate);
    event DelegationRevoked(uint256 delegationId);

    // --- Bitcoin Treasury Management ---
    struct BitcoinTreasury {
        uint256 btcAmount; // Amount in satoshis
        uint256 acquisitionCostUSD; // Cost basis in USD (6 decimals)
        uint256 acquisitionDate;
    }
    
    struct BTCPriceOracle {
        uint256 price; // USD per BTC (6 decimals)
        uint256 lastUpdated;
        address oracleProvider;
    }

    BitcoinTreasury[] public bitcoinTreasury;
    BTCPriceOracle public btcPriceData;
    uint256 public totalBTCHoldings; // in satoshis
    uint256 public treasuryValueUSD; // in USD (6 decimals)
    
    // --- Startup Investments (YC Style) ---
    struct StartupInvestment {
        string name;
        string description;
        uint256 investmentAmount; // In tokens
        uint256 equityPercentage; // Basis points (100 = 1%)
        uint256 valuationCap; // In USD (6 decimals)
        uint256 investmentDate;
        uint256 maturityDate;
        bool active;
    }
    
    mapping(uint256 => StartupInvestment) public startupInvestments;
    uint256 public nextInvestmentId;
    uint256 public totalInvestedAmount;
    
    // --- Events ---
    event BTCTreasuryUpdated(uint256 newBTCAmount, uint256 newUSDValue);
    event BTCPriceUpdated(uint256 price, address oracleProvider);
    event StartupInvestmentCreated(uint256 investmentId, string name, uint256 amount);
    event StartupInvestmentExited(uint256 investmentId, uint256 returnAmount);

    // --- Font & Display Settings ---
    struct FontSettings {
        string fontFamily;
        uint8 fontSize;
        string primaryColor;
        string secondaryColor;
        bool isBold;
        bool isItalic;
        string customCSS;
    }

    mapping(address => FontSettings) public userFontSettings;
    mapping(uint256 => FontSettings) public receiptFontSettings;

    // --- Anointed Roles System ---
    struct AnointedRole {
        string roleName;
        address assignedAddress;
        uint256 anointedDate;
        uint256 expiryDate;
        string privileges;
        bool isActive;
    }

    mapping(bytes32 => AnointedRole) public anointedRoles;
    bytes32[] public roleKeys;
    
    event RoleAnointed(bytes32 roleKey, string roleName, address assignedAddress);
    event RoleRevoked(bytes32 roleKey, string roleName, address revokedAddress);

    // --- Dictionary & Metadata System ---
    struct DictionaryEntry {
        string key;
        string value;
        string language;
        uint256 lastUpdated;
        address updatedBy;
    }

    mapping(bytes32 => DictionaryEntry) public dictionary;
    bytes32[] public dictionaryKeys;
    
    // Adrian Memorial Grant System
    struct AdrianGrant {
        address recipient;
        uint256 amount;
        string purpose;
        uint256 grantDate;
        bool isActive;
    }
    
    mapping(uint256 => AdrianGrant) public adrianGrants;
    uint256 public nextAdrianGrantId;
    uint256 public totalAdrianGrantsAwarded;
    
    event AdrianGrantAwarded(uint256 grantId, address recipient, uint256 amount);

    // --- Regional Settings for SA/UAE ---
    struct RegionalSettings {
        bool supportsShariaCompliance;
        string localCurrency; // AED, SAR, etc.
        uint256 localCurrencyConversionRate; // Rate to local currency (6 decimals)
        string localTimeZone; // e.g. "UTC+4" for UAE
        address regionalAdministrator;
        bool requiresKYC;
    }
    
    mapping(string => RegionalSettings) public regionalSettings;
    string[] public supportedRegions;
    
    event RegionalSettingsUpdated(string region, string localCurrency, uint256 conversionRate);

    // --- Gwen Sudo System ---
    struct GwenAdmin {
        address adminAddress;
        string adminName;
        uint256 accessLevel; // 1-5, where 5 is highest
        bool isActive;
        uint256 appointedTime;
        address appointedBy;
    }

    struct SudoAction {
        uint256 actionId;
        address executor;
        string actionType;
        bytes actionData;
        string reason;
        uint256 timestamp;
        bool reverted;
    }

    mapping(address => GwenAdmin) public gwenAdmins;
    address[] public gwenAdminList;
    mapping(uint256 => SudoAction) public sudoActionLog;
    uint256 public nextSudoActionId;
    bool public gwenOverrideActive;
    uint256 public gwenOverrideExpiry;
    uint256 public gwenQuorum; // Required approval count for high-level actions

    // Events
    event GwenAdminAdded(address indexed admin, string adminName, uint256 accessLevel);
    event GwenAdminRemoved(address indexed admin);
    event GwenActionExecuted(uint256 indexed actionId, address indexed executor, string actionType);
    event GwenOverrideActivated(address indexed activator, uint256 duration);
    event GwenOverrideDeactivated(address indexed deactivator);
    event GwenEmergencyAction(uint256 indexed actionId, string actionType, string reason);

    // --- Citizen Knowledge-weighted Token Democratic Monitoring System ---
    struct KnowledgeTest {
        string testName;
        bytes32 questionHash;
        bytes32 answerHash;
        uint256 maxScore;
        uint256 expiryDays;
    }

    struct UserKnowledgeScore {
        uint256 testId;
        address user;
        uint256 score;
        uint256 timestamp;
        uint256 expiryTime;
    }

    struct Proposal {
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 requiredKnowledgeTestId; // Test required to vote (0 for none)
        uint256 minKnowledgeScore; // Minimum score needed in test
        uint256 minTokensToPropose;
        uint256 minTokensToVote;
        bool executed;
        bool passed;
        bytes executionData;
    }

    struct Vote {
        address voter;
        bool support;
        uint256 weight; // Calculated based on knowledge score and token balance
        string justification;
    }

    // Main storage variables
    mapping(uint256 => KnowledgeTest) public knowledgeTests;
    uint256 public nextKnowledgeTestId = 1;
    
    mapping(address => mapping(uint256 => UserKnowledgeScore)) public userKnowledgeScores;
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(uint256 => address[]) public proposalVoters;
    
    // Governance parameters
    uint256 public quorumPercentage = 10; // 10% of total supply needed
    uint256 public knowledgeWeight = 30; // 30% of vote weight from knowledge
    uint256 public tokenWeight = 70;     // 70% of vote weight from token holdings
    
    // Events
    event KnowledgeTestCreated(uint256 testId, string testName);
    event KnowledgeTestScored(address indexed user, uint256 testId, uint256 score);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event VoteCast(uint256 proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId, bool passed);

    // --- BRC Compatibility System ---
    struct BRCMapping {
        string btcAddress;          // Bitcoin address or inscription ID
        uint256 amount;             // Amount bridged to Bitcoin
        uint256 mappingTimestamp;   // When the mapping was created
        bool active;                // Whether the mapping is active
        string inscriptionId;       // Ordinal inscription ID (for BRC-721)
        string brcType;             // "BRC-20", "BRC-721", etc.
        string brcData;             // Additional BRC-specific data
    }

    struct BridgeOperation {
        address ethAddress;         // Ethereum address
        string btcAddress;          // Bitcoin address
        uint256 amount;             // Amount being bridged
        bool isToBitcoin;           // Direction: true = ETH→BTC, false = BTC→ETH
        uint256 operationTime;      // When the operation was initiated
        bool completed;             // Whether the operation completed
        uint256 completionTime;     // When the operation was completed
        string txHash;              // Transaction hash on target chain
    }

    // Mappings for BRC compatibility
    mapping(address => mapping(uint256 => BRCMapping)) public ethToBrcMappings;
    mapping(address => uint256) public ethToBrcMappingCounts;
    mapping(string => mapping(uint256 => BRCMapping)) public brcToEthMappings;
    mapping(string => uint256) public brcToEthMappingCounts;
    
    mapping(uint256 => BridgeOperation) public bridgeOperations;
    uint256 public nextBridgeOperationId;

    // Bitcoin network parameters
    string public bitcoinNetwork = "mainnet"; // "mainnet", "testnet", "regtest"
    address public bridgeOperator;
    mapping(address => bool) public authorizedBridgeValidators;
    uint256 public requiredValidations = 2; // Number of validators required
    mapping(uint256 => mapping(address => bool)) public operationValidations;
    mapping(uint256 => uint256) public operationValidationCounts;
    
    // Events for BRC compatibility
    event BRCMappingCreated(address indexed ethAddress, string btcAddress, uint256 amount, string brcType);
    event BRCMappingUpdated(address indexed ethAddress, string btcAddress, uint256 mappingId, bool active);
    event BridgeOperationInitiated(uint256 operationId, address indexed ethAddress, string btcAddress, uint256 amount, bool isToBitcoin);
    event BridgeOperationValidated(uint256 operationId, address validator);
    event BridgeOperationCompleted(uint256 operationId, string txHash);

    // --- Knowledge Test Functions ---
    
    // Create a new knowledge test
    function createKnowledgeTest(
        string calldata testName,
        bytes32 questionHash,
        bytes32 answerHash,
        uint256 maxScore,
        uint256 expiryDays
    ) external onlyOwner {
        knowledgeTests[nextKnowledgeTestId] = KnowledgeTest({
            testName: testName,
            questionHash: questionHash,
            answerHash: answerHash,
            maxScore: maxScore,
            expiryDays: expiryDays
        });
        
        emit KnowledgeTestCreated(nextKnowledgeTestId, testName);
        nextKnowledgeTestId++;
    }
    
    // Score a user's knowledge test
    function scoreKnowledgeTest(
        address user, 
        uint256 testId, 
        uint256 score, 
        bytes memory proof
    ) external onlyGwenAdmin {
        require(score <= knowledgeTests[testId].maxScore, "Score exceeds maximum");
        
        // In production, verify the proof cryptographically
        // For now, this is simplified and assumes the admin's verification
        
        uint256 expiryDays = knowledgeTests[testId].expiryDays;
        uint256 expiryTime = block.timestamp + (expiryDays * 1 days);
        
        userKnowledgeScores[user][testId] = UserKnowledgeScore({
            testId: testId,
            user: user,
            score: score,
            timestamp: block.timestamp,
            expiryTime: expiryTime
        });
        
        emit KnowledgeTestScored(user, testId, score);
    }
    
    // Get user's knowledge score
    function getUserKnowledgeScore(address user, uint256 testId) public view returns (uint256) {
        UserKnowledgeScore memory userScore = userKnowledgeScores[user][testId];
        
        if (userScore.expiryTime < block.timestamp) {
            return 0; // Score has expired
        }
        
        return userScore.score;
    }
    
    // --- Proposal Functions ---
    
    // Create a new governance proposal
    function createProposal(
        string calldata title,
        string calldata description,
        uint256 startTime,
        uint256 endTime,
        uint256 requiredKnowledgeTestId,
        uint256 minKnowledgeScore,
        bytes calldata executionData
    ) external notBlocked whenNotPaused {
        require(balanceOf(msg.sender) >= proposals[nextProposalId].minTokensToPropose, "Insufficient tokens to propose");
        require(endTime > startTime, "End time must be after start time");
        require(startTime >= block.timestamp, "Start time must be in the future");
        
        if (requiredKnowledgeTestId > 0) {
            require(getUserKnowledgeScore(msg.sender, requiredKnowledgeTestId) >= minKnowledgeScore, 
                "Proposer lacks required knowledge score");
        }
        
        proposals[nextProposalId] = Proposal({
            title: title,
            description: description,
            proposer: msg.sender,
            startTime: startTime,
            endTime: endTime,
            requiredKnowledgeTestId: requiredKnowledgeTestId,
            minKnowledgeScore: minKnowledgeScore,
            minTokensToPropose: proposals[nextProposalId].minTokensToPropose,
            minTokensToVote: proposals[nextProposalId].minTokensToVote,
            executed: false,
            passed: false,
            executionData: executionData
        });
        
        emit ProposalCreated(nextProposalId, msg.sender, title);
        nextProposalId++;
    }
    
    // Cast a vote on a proposal
    function castVote(
        uint256 proposalId,
        bool support,
        string calldata justification
    ) external notBlocked whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!proposal.executed, "Proposal already executed");
        require(votes[proposalId][msg.sender].voter == address(0), "Already voted");
        require(balanceOf(msg.sender) >= proposal.minTokensToVote, "Insufficient tokens to vote");
        
        // Check knowledge test requirement if specified
        if (proposal.requiredKnowledgeTestId > 0) {
            require(
                getUserKnowledgeScore(msg.sender, proposal.requiredKnowledgeTestId) >= proposal.minKnowledgeScore,
                "Insufficient knowledge score"
            );
        }
        
        // Calculate vote weight based on knowledge and token balance
        uint256 tokenBalance = balanceOf(msg.sender);
        uint256 knowledgeScore = proposal.requiredKnowledgeTestId > 0 
            ? getUserKnowledgeScore(msg.sender, proposal.requiredKnowledgeTestId)
            : 0;
        
        uint256 weight = calculateVoteWeight(tokenBalance, knowledgeScore, proposal.requiredKnowledgeTestId);
        
        // Record the vote
        votes[proposalId][msg.sender] = Vote({
            voter: msg.sender,
            support: support,
            weight: weight,
            justification: justification
        });
        
        proposalVoters[proposalId].push(msg.sender);
        
        emit VoteCast(proposalId, msg.sender, support, weight);
    }
    
    // Calculate vote weight based on token balance and knowledge score
    function calculateVoteWeight(
        uint256 tokenBalance,
        uint256 knowledgeScore,
        uint256 testId
    ) public view returns (uint256) {
        uint256 maxKnowledgeScore = testId > 0 ? knowledgeTests[testId].maxScore : 1;
        
        // Normalize knowledge score to 0-100 range
        uint256 normalizedKnowledgeScore = testId > 0 
            ? (knowledgeScore * 100) / maxKnowledgeScore 
            : 0;
        
        // Calculate weight components
        uint256 tokenComponent = (tokenBalance * tokenWeight) / 100;
        uint256 knowledgeComponent = (normalizedKnowledgeScore * knowledgeWeight) / 100;
        
        // Combined weight (this is a simplified model - more complex models are possible)
        return tokenComponent + knowledgeComponent;
    }
    
    // Execute a proposal after voting has ended
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp > proposal.endTime, "Voting has not ended");
        require(!proposal.executed, "Proposal already executed");
        
        // Calculate results
        uint256 forVotes = 0;
        uint256 againstVotes = 0;
        uint256 totalVoterTokens = 0;
        
        for (uint256 i = 0; i < proposalVoters[proposalId].length; i++) {
            address voter = proposalVoters[proposalId][i];
            Vote storage vote = votes[proposalId][voter];
            
            if (vote.support) {
                forVotes += vote.weight;
            } else {
                againstVotes += vote.weight;
            }
            
            totalVoterTokens += balanceOf(voter);
        }
        
        // Check if quorum reached
        uint256 quorumTokens = (totalSupply() * quorumPercentage) / 100;
        bool quorumReached = totalVoterTokens >= quorumTokens;
        
        // Determine if proposal passed
        bool passed = quorumReached && forVotes > againstVotes;
        proposal.passed = passed;
        proposal.executed = true;
        
        if (passed && proposal.executionData.length > 0) {
            // Execute proposal logic
            // In production, this would typically be handled via a timelock and governance executor
            // For simplicity, we're just marking it as executed here
        }
        
        emit ProposalExecuted(proposalId, passed);
    }
    
    // --- Governance Control Functions ---
    
    // Update governance parameters (only callable by Gwen admins or owner)
    function updateGovernanceParameters(
        uint256 _quorumPercentage,
        uint256 _knowledgeWeight,
        uint256 _tokenWeight,
        uint256 _minTokensToPropose,
        uint256 _minTokensToVote
    ) external onlyGwenLevel(5) {
        require(_knowledgeWeight + _tokenWeight == 100, "Weights must sum to 100");
        require(_quorumPercentage <= 51, "Quorum percentage too high");
        
        quorumPercentage = _quorumPercentage;
        knowledgeWeight = _knowledgeWeight;
        tokenWeight = _tokenWeight;
        
        // Update proposal requirements
        proposals[0].minTokensToPropose = _minTokensToPropose;
        proposals[0].minTokensToVote = _minTokensToVote;
    }

    // Modifiers
    modifier onlyGwenAdmin() {
        require(gwenAdmins[msg.sender].isActive, "Not a Gwen administrator");
        _;
    }

    modifier onlyGwenLevel(uint256 requiredLevel) {
        require(gwenAdmins[msg.sender].isActive, "Not a Gwen administrator");
        require(gwenAdmins[msg.sender].accessLevel >= requiredLevel, "Insufficient Gwen access level");
        _;
    }

    modifier gwenSudoLog(string memory actionType, string memory reason) {
        uint256 actionId = nextSudoActionId++;
        
        // Log the action before execution
        sudoActionLog[actionId] = SudoAction({
            actionId: actionId,
            executor: msg.sender,
            actionType: actionType,
            actionData: msg.data,
            reason: reason,
            timestamp: block.timestamp,
            reverted: false
        });
        
        // Execute the function
        bool success = true;
        try {
            _;
        } catch {
            // Mark as reverted if execution fails
            sudoActionLog[actionId].reverted = true;
            success = false;
        }
        
        if (success) {
            emit GwenActionExecuted(actionId, msg.sender, actionType);
        }
    }

    // --- Gwen Admin Management Functions ---
    
    // Appoint a new Gwen administrator (only contract owner can do this)
    function appointGwenAdmin(
        address admin,
        string calldata adminName,
        uint256 accessLevel
    ) external onlyOwner {
        require(admin != address(0), "Invalid admin address");
        require(accessLevel > 0 && accessLevel <= 5, "Access level must be 1-5");
        require(!gwenAdmins[admin].isActive, "Already a Gwen admin");
        
        gwenAdmins[admin] = GwenAdmin({
            adminAddress: admin,
            adminName: adminName,
            accessLevel: accessLevel,
            isActive: true,
            appointedTime: block.timestamp,
            appointedBy: msg.sender
        });
        
        gwenAdminList.push(admin);
        emit GwenAdminAdded(admin, adminName, accessLevel);
    }
    
    // Remove a Gwen administrator
    function removeGwenAdmin(address admin) external onlyOwner gwenSudoLog("RemoveGwenAdmin", "Admin removal") {
        require(gwenAdmins[admin].isActive, "Not an active Gwen admin");
        gwenAdmins[admin].isActive = false;
        
        emit GwenAdminRemoved(admin);
    }
    
    // Change access level of a Gwen administrator
    function changeGwenAccessLevel(address admin, uint256 newLevel) external onlyGwenLevel(5) gwenSudoLog("ChangeGwenLevel", "Access level change") {
        require(gwenAdmins[admin].isActive, "Not an active Gwen admin");
        require(newLevel > 0 && newLevel <= 5, "Access level must be 1-5");
        
        gwenAdmins[admin].accessLevel = newLevel;
    }
    
    // Set the required quorum for high-level actions
    function setGwenQuorum(uint256 newQuorum) external onlyOwner {
        gwenQuorum = newQuorum;
    }
    
    // --- Gwen Emergency Functions ---
    
    // Activate Gwen override mode (temporarily gives special permissions)
    function activateGwenOverride(uint256 durationHours) external onlyGwenLevel(5) gwenSudoLog("ActivateOverride", "Emergency override") {
        gwenOverrideActive = true;
        gwenOverrideExpiry = block.timestamp + (durationHours * 1 hours);
        
        emit GwenOverrideActivated(msg.sender, durationHours);
    }
    
    // Deactivate Gwen override mode
    function deactivateGwenOverride() external onlyGwenLevel(5) gwenSudoLog("DeactivateOverride", "Override ended") {
        gwenOverrideActive = false;
        emit GwenOverrideDeactivated(msg.sender);
    }
    
    // Check if Gwen override is active
    function isGwenOverrideActive() public view returns (bool) {
        if (!gwenOverrideActive) {
            return false;
        }
        
        return block.timestamp <= gwenOverrideExpiry;
    }
    
    // --- Gwen Emergency Actions ---
    
    // Emergency pause/unpause contract (overrides owner)
    function gwenEmergencyPause(bool paused, string calldata reason) external onlyGwenLevel(4) gwenSudoLog("EmergencyPause", reason) {
        emergencyPause = paused;
        emit SecurityStateChanged(paused);
        emit GwenEmergencyAction(nextSudoActionId - 1, "EmergencyPause", reason);
    }
    
    // Emergency block/unblock address (overrides owner)
    function gwenEmergencyBlockAddress(address addr, bool blocked, string calldata reason) external onlyGwenLevel(4) gwenSudoLog("EmergencyBlock", reason) {
        blockedAddresses[addr] = blocked;
        emit GwenEmergencyAction(nextSudoActionId - 1, "EmergencyBlock", reason);
    }
    
    // Emergency transaction execution (for critical situations)
    function gwenEmergencyExecute(
        address target,
        bytes calldata data,
        string calldata reason
    ) external onlyGwenLevel(5) gwenSudoLog("EmergencyExecute", reason) {
        require(isGwenOverrideActive(), "Gwen override not active");
        
        (bool success, ) = target.call(data);
        require(success, "Gwen emergency execution failed");
        
        emit GwenEmergencyAction(nextSudoActionId - 1, "EmergencyExecute", reason);
    }
    
    // Emergency token recovery (retrieve stuck tokens)
    function gwenEmergencyRecover(
        address token,
        address to,
        uint256 amount,
        string calldata reason
    ) external onlyGwenLevel(5) gwenSudoLog("EmergencyRecover", reason) {
        require(isGwenOverrideActive(), "Gwen override not active");
        
        if (token == address(0)) {
            // Recover ETH
            payable(to).transfer(amount);
        } else if (token == address(this)) {
            // Recover native tokens
            _transfer(address(this), to, amount);
        } else {
            // Recover other ERC20 tokens
            IERC20(token).transfer(to, amount);
        }
        
        emit GwenEmergencyAction(nextSudoActionId - 1, "EmergencyRecover", reason);
    }
    
    // --- Gwen Audit Functions ---
    
    // Get all Gwen administrators
    function getAllGwenAdmins() external view returns (address[] memory) {
        return gwenAdminList;
    }
    
    // Get action log entry
    function getSudoActionLog(uint256 actionId) external view returns (
        address executor,
        string memory actionType,
        bytes memory actionData,
        string memory reason,
        uint256 timestamp,
        bool reverted
    ) {
        SudoAction storage action = sudoActionLog[actionId];
        return (
            action.executor,
            action.actionType,
            action.actionData,
            action.reason,
            action.timestamp,
            action.reverted
        );
    }
    
    // Get recent action logs
    function getRecentSudoActions(uint256 count) external view returns (uint256[] memory) {
        uint256 resultCount = count;
        if (nextSudoActionId < count) {
            resultCount = nextSudoActionId;
        }
        
        uint256[] memory actionIds = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            actionIds[i] = nextSudoActionId - i - 1;
        }
        
        return actionIds;
    }

    // --- Function Modifiers ---
    modifier whenNotPaused() {
        require(!emergencyPause, "Contract is paused");
        _;
    }

    modifier onlyTrustedOperator() {
        require(trustedOperators[msg.sender] || msg.sender == owner(), "Not a trusted operator");
        _;
    }

    modifier canManageFor(address user) {
        require(msg.sender == user || delegateApprovals[user][msg.sender], "Not authorized to manage");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        rewardRatePerSecond = 1e16; // Example: 0.01 tokens per second
    }

    // Block an address from interacting with the contract
    function blockAddress(address addr) external onlyOwner {
        blockedAddresses[addr] = true;
    }

    // Unblock an address
    function unblockAddress(address addr) external onlyOwner {
        blockedAddresses[addr] = false;
    }

    // Modifier to check if the caller is blocked
    modifier notBlocked() {
        require(!blockedAddresses[msg.sender], "Address is blocked");
        _;
    }

    // --- Security Functions ---
    function setEmergencyPause(bool paused) external onlyOwner {
        emergencyPause = paused;
        emit SecurityStateChanged(paused);
    }

    function addTrustedOperator(address operator) external onlyOwner {
        trustedOperators[operator] = true;
    }

    function removeTrustedOperator(address operator) external onlyOwner {
        trustedOperators[operator] = false;
    }

    // --- Token Configuration ---
    function setTokenConfig(uint256 _maxSupply, uint256 _burnRate, uint256 _transferTaxRate) external onlyOwner {
        require(_burnRate <= 500, "Burn rate too high"); // Max 5%
        require(_transferTaxRate <= 500, "Transfer tax too high"); // Max 5%

        tokenConfig = TokenConfig({
            maxSupply: _maxSupply,
            burnRate: _burnRate,
            transferTaxRate: _transferTaxRate
        });
    }

    // Override ERC20 transfer with burn and tax logic
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override whenNotPaused {
        uint256 burnAmount = (amount * tokenConfig.burnRate) / 10000;
        uint256 taxAmount = (amount * tokenConfig.transferTaxRate) / 10000;
        uint256 transferAmount = amount - burnAmount - taxAmount;

        if (burnAmount > 0) {
            super._burn(sender, burnAmount);
            totalBurned += burnAmount;
        }

        if (taxAmount > 0) {
            super._transfer(sender, address(this), taxAmount);
        }

        super._transfer(sender, recipient, transferAmount);
    }

    // --- Escrow Functions ---
    function createEscrow(address recipient, uint256 amount, uint256 releaseTime) external notBlocked whenNotPaused {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(releaseTime > block.timestamp, "Release time must be in future");

        _transfer(msg.sender, address(this), amount);

        escrows[nextEscrowId] = Escrow({
            depositor: msg.sender,
            recipient: recipient,
            amount: amount,
            releaseTime: releaseTime,
            released: false
        });

        emit EscrowCreated(nextEscrowId, msg.sender, recipient, amount);
        nextEscrowId++;
    }

    function releaseEscrow(uint256 escrowId) external whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.released, "Escrow already released");
        require(block.timestamp >= escrow.releaseTime, "Release time not reached");
        require(msg.sender == escrow.depositor || msg.sender == escrow.recipient || msg.sender == owner(), "Not authorized");

        escrow.released = true;
        _transfer(address(this), escrow.recipient, escrow.amount);

        emit EscrowReleased(escrowId);
    }

    function cancelEscrow(uint256 escrowId) external whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.released, "Escrow already released");
        require(msg.sender == escrow.depositor || msg.sender == owner(), "Not authorized");

        escrow.released = true;
        _transfer(address(this), escrow.depositor, escrow.amount);
    }

    // --- Notification Functions ---
    function setNotificationsEnabled(bool enabled) external {
        notificationsEnabled[msg.sender] = enabled;
    }

    function addNotification(address user, string calldata notificationType, string calldata message) external onlyTrustedOperator {
        if (notificationsEnabled[user]) {
            userNotifications[user].push(message);
            emit Notification(user, notificationType, message);
        }
    }

    function getUserNotifications(address user) external view returns (string[] memory) {
        return userNotifications[user];
    }

    // --- Delegation Functions ---
    function createDelegation(address delegate, bool canTransfer, bool canManage, bool canClaim) external whenNotPaused {
        delegateApprovals[msg.sender][delegate] = true;

        delegations[nextDelegationId] = Delegation({
            delegator: msg.sender,
            delegate: delegate,
            canTransfer: canTransfer,
            canManage: canManage,
            canClaim: canClaim
        });

        emit DelegationCreated(nextDelegationId, msg.sender, delegate);
        nextDelegationId++;
    }

    function revokeDelegation(address delegate) external {
        delegateApprovals[msg.sender][delegate] = false;

        // Find and mark delegations as revoked in event
        for (uint256 i = 0; i < nextDelegationId; i++) {
            if (delegations[i].delegator == msg.sender && delegations[i].delegate == delegate) {
                emit DelegationRevoked(i);
            }
        }
    }

    function transferForDelegate(address delegator, address recipient, uint256 amount) external whenNotPaused {
        require(delegateApprovals[delegator][msg.sender], "Not approved delegate");

        // Find delegation to check permissions
        bool hasPermission = false;
        for (uint256 i = 0; i < nextDelegationId; i++) {
            Delegation storage delegation = delegations[i];
            if (delegation.delegator == delegator && delegation.delegate == msg.sender && delegation.canTransfer) {
                hasPermission = true;
                break;
            }
        }

        require(hasPermission, "Delegate not authorized to transfer");
        _transfer(delegator, recipient, amount);
    }

    // --- Bitcoin Treasury Management Functions ---
    
    // Update BTC price from trusted oracle
    function updateBTCPrice(uint256 price) external onlyTrustedOperator {
        btcPriceData.price = price;
        btcPriceData.lastUpdated = block.timestamp;
        btcPriceData.oracleProvider = msg.sender;
        
        // Recalculate treasury value
        treasuryValueUSD = (totalBTCHoldings * price) / 1e8; // Convert satoshis to BTC
        
        emit BTCPriceUpdated(price, msg.sender);
    }
    
    // Add BTC holdings to treasury (record keeping)
    function addBTCToTreasury(uint256 btcAmount, uint256 acquisitionCostUSD) external onlyOwner {
        BitcoinTreasury memory newAcquisition = BitcoinTreasury({
            btcAmount: btcAmount,
            acquisitionCostUSD: acquisitionCostUSD,
            acquisitionDate: block.timestamp
        });
        
        bitcoinTreasury.push(newAcquisition);
        totalBTCHoldings += btcAmount;
        
        // Update treasury value
        treasuryValueUSD = (totalBTCHoldings * btcPriceData.price) / 1e8; // Convert satoshis to BTC
        
        emit BTCTreasuryUpdated(totalBTCHoldings, treasuryValueUSD);
    }
    
    // Get average acquisition cost of BTC holdings
    function getAverageBTCAcquisitionCost() external view returns (uint256) {
        if (totalBTCHoldings == 0) return 0;
        
        uint256 totalCost = 0;
        for (uint256 i = 0; i < bitcoinTreasury.length; i++) {
            totalCost += bitcoinTreasury[i].acquisitionCostUSD;
        }
        
        return (totalCost * 1e8) / totalBTCHoldings; // USD per BTC (6 decimals)
    }
    
    // --- Startup Investment Functions (YC Style) ---
    
    // Create a new startup investment
    function createStartupInvestment(
        string calldata name,
        string calldata description,
        uint256 investmentAmount,
        uint256 equityPercentage,
        uint256 valuationCap,
        uint256 maturityDate
    ) external onlyOwner whenNotPaused {
        require(balanceOf(address(this)) >= investmentAmount, "Insufficient treasury balance");
        require(maturityDate > block.timestamp, "Maturity date must be in future");
        
        startupInvestments[nextInvestmentId] = StartupInvestment({
            name: name,
            description: description,
            investmentAmount: investmentAmount,
            equityPercentage: equityPercentage,
            valuationCap: valuationCap,
            investmentDate: block.timestamp,
            maturityDate: maturityDate,
            active: true
        });
        
        totalInvestedAmount += investmentAmount;
        
        emit StartupInvestmentCreated(nextInvestmentId, name, investmentAmount);
        nextInvestmentId++;
    }
    
    // Record a startup investment exit
    function exitStartupInvestment(uint256 investmentId, uint256 returnAmount) external onlyOwner {
        StartupInvestment storage investment = startupInvestments[investmentId];
        require(investment.active, "Investment already exited");
        
        investment.active = false;
        totalInvestedAmount -= investment.investmentAmount;
        
        // Mint return tokens to treasury
        _mint(address(this), returnAmount);
        
        emit StartupInvestmentExited(investmentId, returnAmount);
    }
    
    // Get all active investments
    function getActiveInvestments() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active investments
        for (uint256 i = 0; i < nextInvestmentId; i++) {
            if (startupInvestments[i].active) {
                activeCount++;
            }
        }
        
        // Create result array
        uint256[] memory activeInvestments = new uint256[](activeCount);
        uint256 currentIndex = 0;
        
        // Fill result array
        for (uint256 i = 0; i < nextInvestmentId; i++) {
            if (startupInvestments[i].active) {
                activeInvestments[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return activeInvestments;
    }
    
    // Calculate ROI for an investment (returns percentage, 10000 = 100%)
    function calculateInvestmentROI(uint256 investmentId, uint256 currentValue) external view returns (uint256) {
        StartupInvestment storage investment = startupInvestments[investmentId];
        if (investment.investmentAmount == 0) return 0;
        
        // ROI = (Current Value - Investment) / Investment * 100
        uint256 roi = ((currentValue - investment.investmentAmount) * 10000) / investment.investmentAmount;
        return roi;
    }
    
    // --- Portfolio Management Functions ---
    
    // Get total assets under management (USD value of treasury + investments)
    function getTotalAssetsUnderManagement() external view returns (uint256) {
        // BTC value + token treasury + invested amount
        return treasuryValueUSD + (balanceOf(address(this)) * getEstimatedTokenPriceUSD()) / 1e18 + totalInvestedAmount;
    }
    
    // Simple estimated token price in USD (6 decimals) - would use an oracle in production
    function getEstimatedTokenPriceUSD() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (treasuryValueUSD * 1e18) / totalSupply();
    }

    // --- Token Distribution & Sales ---
    struct DistributionPlan {
        string name;
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    struct SaleRound {
        string name;
        uint256 tokenPrice; // Price in wei per token
        uint256 totalTokens;
        uint256 soldTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 minPurchase;
        uint256 maxPurchase;
        bool whitelistEnabled;
        bool active;
    }
    
    struct Receipt {
        address buyer;
        uint256 amountPaid;
        uint256 tokensBought;
        uint256 timestamp;
        string metadata;
        uint256 saleRoundId;
    }

    mapping(uint256 => DistributionPlan) public distributionPlans;
    uint256 public nextDistributionPlanId;
    
    mapping(uint256 => SaleRound) public saleRounds;
    uint256 public nextSaleRoundId;
    
    mapping(uint256 => Receipt) public receipts;
    uint256 public nextReceiptId;
    
    mapping(address => mapping(uint256 => bool)) public whitelist;
    mapping(address => uint256[]) public userReceipts;

    // Events
    event DistributionPlanCreated(uint256 indexed planId, string name, uint256 totalAmount);
    event TokensDistributed(uint256 indexed planId, address recipient, uint256 amount);
    event SaleRoundCreated(uint256 indexed roundId, string name, uint256 tokenPrice);
    event TokensPurchased(uint256 indexed roundId, address buyer, uint256 amount, uint256 receiptId);
    event ReceiptGenerated(uint256 indexed receiptId, address buyer, uint256 amount);

    // --- Distribution Functions ---
    
    // Create a new distribution plan
    function createDistributionPlan(
        string calldata name,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner whenNotPaused {
        require(totalAmount > 0, "Amount must be greater than zero");
        require(endTime > startTime, "End time must be after start time");
        
        distributionPlans[nextDistributionPlanId] = DistributionPlan({
            name: name,
            totalAmount: totalAmount,
            remainingAmount: totalAmount,
            startTime: startTime,
            endTime: endTime,
            active: true
        });
        
        emit DistributionPlanCreated(nextDistributionPlanId, name, totalAmount);
        nextDistributionPlanId++;
    }
    
    // Distribute tokens to a recipient from a distribution plan
    function distributeTokens(
        uint256 planId,
        address recipient,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        DistributionPlan storage plan = distributionPlans[planId];
        require(plan.active, "Distribution plan not active");
        require(block.timestamp >= plan.startTime, "Distribution not started");
        require(block.timestamp <= plan.endTime, "Distribution ended");
        require(amount <= plan.remainingAmount, "Insufficient tokens in plan");
        
        plan.remainingAmount -= amount;
        _mint(recipient, amount);
        
        emit TokensDistributed(planId, recipient, amount);
    }
    
    // --- Sale Functions ---
    
    // Create a new sale round
    function createSaleRound(
        string calldata name,
        uint256 tokenPrice,
        uint256 totalTokens,
        uint256 startTime,
        uint256 endTime,
        uint256 minPurchase,
        uint256 maxPurchase,
        bool whitelistEnabled
    ) external onlyOwner whenNotPaused {
        require(tokenPrice > 0, "Price must be greater than zero");
        require(totalTokens > 0, "Total tokens must be greater than zero");
        require(endTime > startTime, "End time must be after start time");
        
        saleRounds[nextSaleRoundId] = SaleRound({
            name: name,
            tokenPrice: tokenPrice,
            totalTokens: totalTokens,
            soldTokens: 0,
            startTime: startTime,
            endTime: endTime,
            minPurchase: minPurchase,
            maxPurchase: maxPurchase,
            whitelistEnabled: whitelistEnabled,
            active: true
        });
        
        emit SaleRoundCreated(nextSaleRoundId, name, tokenPrice);
        nextSaleRoundId++;
    }
    
    // Add addresses to whitelist for a sale round
    function addToWhitelist(uint256 roundId, address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]][roundId] = true;
        }
    }
    
    // Remove addresses from whitelist for a sale round
    function removeFromWhitelist(uint256 roundId, address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]][roundId] = false;
        }
    }
    
    // Buy tokens from a sale round
    function buyTokens(uint256 roundId, uint256 tokenAmount) external payable whenNotPaused notBlocked {
        SaleRound storage round = saleRounds[roundId];
        require(round.active, "Sale round not active");
        require(block.timestamp >= round.startTime, "Sale not started");
        require(block.timestamp <= round.endTime, "Sale ended");
        require(tokenAmount >= round.minPurchase, "Below minimum purchase");
        require(tokenAmount <= round.maxPurchase, "Exceeds maximum purchase");
        require(tokenAmount <= (round.totalTokens - round.soldTokens), "Insufficient tokens available");
        
        if (round.whitelistEnabled) {
            require(whitelist[msg.sender][roundId], "Address not whitelisted");
        }
        
        uint256 cost = tokenAmount * round.tokenPrice;
        require(msg.value >= cost, "Insufficient payment");
        
        // Update state
        round.soldTokens += tokenAmount;
        
        // Mint tokens to buyer
        _mint(msg.sender, tokenAmount);
        
        // Generate receipt
        Receipt memory receipt = Receipt({
            buyer: msg.sender,
            amountPaid: cost,
            tokensBought: tokenAmount,
            timestamp: block.timestamp,
            metadata: string(abi.encodePacked("Sale Round: ", round.name)),
            saleRoundId: roundId
        });
        
        receipts[nextReceiptId] = receipt;
        userReceipts[msg.sender].push(nextReceiptId);
        
        emit TokensPurchased(roundId, msg.sender, tokenAmount, nextReceiptId);
        emit ReceiptGenerated(nextReceiptId, msg.sender, tokenAmount);
        
        nextReceiptId++;
        
        // Refund excess payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    // --- Receipt Functions ---
    
    // Get receipt details
    function getReceipt(uint256 receiptId) external view returns (
        address buyer,
        uint256 amountPaid,
        uint256 tokensBought,
        uint256 timestamp,
        string memory metadata
    ) {
        Receipt storage receipt = receipts[receiptId];
        return (
            receipt.buyer,
            receipt.amountPaid,
            receipt.tokensBought,
            receipt.timestamp,
            receipt.metadata
        );
    }
    
    // Get all receipts for a user
    function getUserReceipts(address user) external view returns (uint256[] memory) {
        return userReceipts[user];
    }
    
    // Generate a printable receipt (returns a formatted string)
    function generatePrintableReceipt(uint256 receiptId) external view returns (string memory) {
        Receipt storage receipt = receipts[receiptId];
        SaleRound storage round = saleRounds[receipt.saleRoundId];
        
        return string(abi.encodePacked(
            "RECEIPT #", toString(receiptId), "\n",
            "Date: ", toString(receipt.timestamp), "\n",
            "Buyer: ", toString(receipt.buyer), "\n",
            "Sale Round: ", round.name, "\n",
            "Amount Paid: ", toString(receipt.amountPaid), " wei\n",
            "Tokens Purchased: ", toString(receipt.tokensBought), "\n",
            "Token Price: ", toString(round.tokenPrice), " wei\n",
            "StreamToken Official Receipt"
        ));
    }
    
    // Helper function to convert uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    // Helper function to convert address to string
    function toString(address account) internal pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }
    
    // Helper function to convert bytes to string
    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        
        return string(str);
    }

    // --- Font Settings Functions ---
    
    // Set user font preferences
    function setUserFontSettings(
        string calldata fontFamily,
        uint8 fontSize,
        string calldata primaryColor,
        string calldata secondaryColor,
        bool isBold,
        bool isItalic,
        string calldata customCSS
    ) external notBlocked {
        userFontSettings[msg.sender] = FontSettings({
            fontFamily: fontFamily,
            fontSize: fontSize,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            isBold: isBold,
            isItalic: isItalic,
            customCSS: customCSS
        });
    }
    
    // Set receipt font settings
    function setReceiptFontSettings(
        uint256 receiptId,
        string calldata fontFamily,
        uint8 fontSize,
        string calldata primaryColor,
        string calldata secondaryColor,
        bool isBold,
        bool isItalic,
        string calldata customCSS
    ) external {
        Receipt storage receipt = receipts[receiptId];
        require(msg.sender == receipt.buyer || msg.sender == owner(), "Not authorized");
        
        receiptFontSettings[receiptId] = FontSettings({
            fontFamily: fontFamily,
            fontSize: fontSize,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            isBold: isBold,
            isItalic: isItalic,
            customCSS: customCSS
        });
    }
    
    // --- Anointed Roles Functions ---
    
    // Anoint an address to a role
    function anointRole(
        string calldata roleName,
        address assignedAddress,
        uint256 durationDays,
        string calldata privileges
    ) external onlyOwner whenNotPaused {
        require(assignedAddress != address(0), "Cannot anoint zero address");
        
        bytes32 roleKey = keccak256(abi.encodePacked(roleName, assignedAddress));
        uint256 expiryDate = block.timestamp + (durationDays * 1 days);
        
        anointedRoles[roleKey] = AnointedRole({
            roleName: roleName,
            assignedAddress: assignedAddress,
            anointedDate: block.timestamp,
            expiryDate: expiryDate,
            privileges: privileges,
            isActive: true
        });
        
        roleKeys.push(roleKey);
        emit RoleAnointed(roleKey, roleName, assignedAddress);
    }
    
    // Revoke an anointed role
    function revokeRole(bytes32 roleKey) external onlyOwner {
        AnointedRole storage role = anointedRoles[roleKey];
        require(role.isActive, "Role not active");
        
        role.isActive = false;
        emit RoleRevoked(roleKey, role.roleName, role.assignedAddress);
    }
    
    // Check if an address has an anointed role
    function hasRole(string calldata roleName, address checkAddress) external view returns (bool) {
        bytes32 roleKey = keccak256(abi.encodePacked(roleName, checkAddress));
        AnointedRole storage role = anointedRoles[roleKey];
        
        return role.isActive && role.expiryDate >= block.timestamp;
    }
    
    // --- Dictionary Functions ---
    
    // Add or update a dictionary entry
    function setDictionaryEntry(
        string calldata key,
        string calldata value,
        string calldata language
    ) external onlyTrustedOperator {
        bytes32 entryKey = keccak256(abi.encodePacked(key, language));
        
        // Check if this is a new entry
        bool isNew = bytes(dictionary[entryKey].key).length == 0;
        
        dictionary[entryKey] = DictionaryEntry({
            key: key,
            value: value,
            language: language,
            lastUpdated: block.timestamp,
            updatedBy: msg.sender
        });
        
        if (isNew) {
            dictionaryKeys.push(entryKey);
        }
    }
    
    // Get a dictionary entry
    function getDictionaryEntry(string calldata key, string calldata language) external view returns (string memory) {
        bytes32 entryKey = keccak256(abi.encodePacked(key, language));
        return dictionary[entryKey].value;
    }
    
    // --- Adrian Memorial Grant System ---
    
    // Create a new Adrian grant
    function createAdrianGrant(
        address recipient,
        uint256 amount,
        string calldata purpose
    ) external onlyOwner whenNotPaused {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Grant amount must be greater than zero");
        
        adrianGrants[nextAdrianGrantId] = AdrianGrant({
            recipient: recipient,
            amount: amount,
            purpose: purpose,
            grantDate: block.timestamp,
            isActive: true
        });
        
        totalAdrianGrantsAwarded += amount;
        
        // Transfer tokens to recipient
        _mint(recipient, amount);
        
        emit AdrianGrantAwarded(nextAdrianGrantId, recipient, amount);
        nextAdrianGrantId++;
    }
    
    // Revoke an Adrian grant
    function revokeAdrianGrant(uint256 grantId) external onlyOwner {
        AdrianGrant storage grant = adrianGrants[grantId];
        require(grant.isActive, "Grant not active");
        
        grant.isActive = false;
        totalAdrianGrantsAwarded -= grant.amount;
    }
    
    // --- Regional Settings for SA/UAE ---
    
    // Add or update regional settings
    function setRegionalSettings(
        string calldata region,
        bool supportsShariaCompliance,
        string calldata localCurrency,
        uint256 localCurrencyConversionRate,
        string calldata localTimeZone,
        address regionalAdministrator,
        bool requiresKYC
    ) external onlyOwner {
        bool isNew = bytes(regionalSettings[region].localCurrency).length == 0;
        
        regionalSettings[region] = RegionalSettings({
            supportsShariaCompliance: supportsShariaCompliance,
            localCurrency: localCurrency,
            localCurrencyConversionRate: localCurrencyConversionRate,
            localTimeZone: localTimeZone,
            regionalAdministrator: regionalAdministrator,
            requiresKYC: requiresKYC
        });
        
        if (isNew) {
            supportedRegions.push(region);
        }
        
        emit RegionalSettingsUpdated(region, localCurrency, localCurrencyConversionRate);
    }
    
    // Get price in local currency
    function getPriceInLocalCurrency(uint256 tokenAmount, string calldata region) external view returns (uint256) {
        RegionalSettings storage settings = regionalSettings[region];
        require(bytes(settings.localCurrency).length > 0, "Region not configured");
        
        uint256 priceUSD = tokenAmount * getEstimatedTokenPriceUSD();
        return (priceUSD * settings.localCurrencyConversionRate) / 1e6;
    }
    
    // Check if transaction is permitted in region
    function isTransactionPermittedInRegion(
        address sender, 
        address recipient, 
        uint256 amount, 
        string calldata region
    ) external view returns (bool) {
        RegionalSettings storage settings = regionalSettings[region];
        
        // Basic implementation - additional logic would be needed for real compliance
        if (settings.requiresKYC) {
            // Would check KYC status here
        }
        
        if (settings.supportsShariaCompliance) {
            // Would implement Sharia compliance checks here
        }
        
        return true; // Placeholder for actual implementation
    }

    // --- BRC Bridge and Mapping Functions ---

    // Set Bitcoin network type
    function setBitcoinNetwork(string calldata network) external onlyOwner {
        require(
            keccak256(bytes(network)) == keccak256(bytes("mainnet")) ||
            keccak256(bytes(network)) == keccak256(bytes("testnet")) ||
            keccak256(bytes(network)) == keccak256(bytes("regtest")),
            "Invalid network type"
        );
        bitcoinNetwork = network;
    }

    // Set bridge operator
    function setBridgeOperator(address operator) external onlyOwner {
        bridgeOperator = operator;
    }

    // Add a bridge validator
    function addBridgeValidator(address validator) external onlyOwner {
        authorizedBridgeValidators[validator] = true;
    }

    // Remove a bridge validator
    function removeBridgeValidator(address validator) external onlyOwner {
        authorizedBridgeValidators[validator] = false;
    }

    // Set required validations
    function setRequiredValidations(uint256 count) external onlyOwner {
        requiredValidations = count;
    }

    // Create a BRC mapping for Ethereum address
    function createBRCMapping(
        address ethAddress,
        string calldata btcAddress,
        uint256 amount,
        string calldata inscriptionId,
        string calldata brcType,
        string calldata brcData
    ) external onlyGwenAdmin whenNotPaused {
        uint256 mappingId = ethToBrcMappingCounts[ethAddress];
        
        ethToBrcMappings[ethAddress][mappingId] = BRCMapping({
            btcAddress: btcAddress,
            amount: amount,
            mappingTimestamp: block.timestamp,
            active: true,
            inscriptionId: inscriptionId,
            brcType: brcType,
            brcData: brcData
        });
        
        ethToBrcMappingCounts[ethAddress]++;
        
        uint256 btcMappingId = brcToEthMappingCounts[btcAddress];
        brcToEthMappings[btcAddress][btcMappingId] = ethToBrcMappings[ethAddress][mappingId];
        brcToEthMappingCounts[btcAddress]++;
        
        emit BRCMappingCreated(ethAddress, btcAddress, amount, brcType);
    }

    // Initiate bridge to Bitcoin
    function bridgeTokensToBitcoin(
        string calldata btcAddress,
        uint256 amount
    ) external notBlocked whenNotPaused {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Lock tokens in the contract
        _transfer(msg.sender, address(this), amount);
        
        // Create bridge operation
        bridgeOperations[nextBridgeOperationId] = BridgeOperation({
            ethAddress: msg.sender,
            btcAddress: btcAddress,
            amount: amount,
            isToBitcoin: true,
            operationTime: block.timestamp,
            completed: false,
            completionTime: 0,
            txHash: ""
        });
        
        emit BridgeOperationInitiated(
            nextBridgeOperationId,
            msg.sender,
            btcAddress,
            amount,
            true
        );
        
        nextBridgeOperationId++;
    }

    // Validate a bridge operation
    function validateBridgeOperation(uint256 operationId) external whenNotPaused {
        require(authorizedBridgeValidators[msg.sender], "Not a bridge validator");
        require(!bridgeOperations[operationId].completed, "Operation already completed");
        require(!operationValidations[operationId][msg.sender], "Already validated by this validator");
        
        operationValidations[operationId][msg.sender] = true;
        operationValidationCounts[operationId]++;
        
        emit BridgeOperationValidated(operationId, msg.sender);
        
        // If we have enough validations, complete the operation
        if (operationValidationCounts[operationId] >= requiredValidations) {
            completeBridgeOperation(operationId, "");
        }
    }

    // Complete a bridge operation
    function completeBridgeOperation(uint256 operationId, string memory txHash) public {
        require(msg.sender == bridgeOperator || operationValidationCounts[operationId] >= requiredValidations, "Not authorized");
        require(!bridgeOperations[operationId].completed, "Operation already completed");
        
        BridgeOperation storage operation = bridgeOperations[operationId];
        operation.completed = true;
        operation.completionTime = block.timestamp;
        operation.txHash = txHash;
        
        // Handle token movement for BTC to ETH operations
        if (!operation.isToBitcoin) {
            // Mint tokens when bridging from Bitcoin to Ethereum
            _mint(operation.ethAddress, operation.amount);
        }
        
        emit BridgeOperationCompleted(operationId, txHash);
    }

    // Initiate bridge from Bitcoin (called by bridge operator)
    function bridgeTokensFromBitcoin(
        address ethAddress,
        string calldata btcAddress,
        string calldata txHash,
        uint256 amount
    ) external whenNotPaused {
        require(msg.sender == bridgeOperator, "Not bridge operator");
        
        // Create bridge operation
        bridgeOperations[nextBridgeOperationId] = BridgeOperation({
            ethAddress: ethAddress,
            btcAddress: btcAddress,
            amount: amount,
            isToBitcoin: false,
            operationTime: block.timestamp,
            completed: false,
            completionTime: 0,
            txHash: txHash
        });
        
        emit BridgeOperationInitiated(
            nextBridgeOperationId,
            ethAddress,
            btcAddress,
            amount,
            false
        );
        
        // For bridge from Bitcoin, we require validations
        // When enough validations are received, tokens will be minted
        
        nextBridgeOperationId++;
    }

    // Cancel a bridge operation (only for operations that haven't been completed)
    function cancelBridgeOperation(uint256 operationId) external {
        BridgeOperation storage operation = bridgeOperations[operationId];
        
        require(!operation.completed, "Operation already completed");
        require(
            msg.sender == owner() ||
            msg.sender == operation.ethAddress ||
            msg.sender == bridgeOperator,
            "Not authorized"
        );
        
        // If this was a bridge to Bitcoin, return the locked tokens
        if (operation.isToBitcoin) {
            _transfer(address(this), operation.ethAddress, operation.amount);
        }
        
        // Mark as completed but with empty txHash to indicate cancellation
        operation.completed = true;
        operation.completionTime = block.timestamp;
        
        emit BridgeOperationCompleted(operationId, "CANCELLED");
    }
    
    // Get an ETH to BRC mapping
    function getEthToBrcMapping(address ethAddress, uint256 mappingId) 
        external view returns (
            string memory btcAddress,
            uint256 amount,
            uint256 mappingTimestamp,
            bool active,
            string memory inscriptionId,
            string memory brcType,
            string memory brcData
        ) 
    {
        BRCMapping storage mapping_ = ethToBrcMappings[ethAddress][mappingId];
        return (
            mapping_.btcAddress,
            mapping_.amount,
            mapping_.mappingTimestamp,
            mapping_.active,
            mapping_.inscriptionId,
            mapping_.brcType,
            mapping_.brcData
        );
    }
    
    // Get a BRC to ETH mapping
    function getBrcToEthMapping(string calldata btcAddress, uint256 mappingId)
        external view returns (
            string memory btcAddr,
            uint256 amount,
            uint256 mappingTimestamp,
            bool active,
            string memory inscriptionId,
            string memory brcType,
            string memory brcData
        )
    {
        BRCMapping storage mapping_ = brcToEthMappings[btcAddress][mappingId];
        return (
            mapping_.btcAddress,
            mapping_.amount,
            mapping_.mappingTimestamp,
            mapping_.active,
            mapping_.inscriptionId,
            mapping_.brcType,
            mapping_.brcData
        );
    }

    // Get bridge operation details
    function getBridgeOperation(uint256 operationId)
        external view returns (
            address ethAddress,
            string memory btcAddress,
            uint256 amount,
            bool isToBitcoin,
            uint256 operationTime,
            bool completed,
            uint256 completionTime,
            string memory txHash,
            uint256 validationCount
        )
    {
        BridgeOperation storage operation = bridgeOperations[operationId];
        return (
            operation.ethAddress,
            operation.btcAddress,
            operation.amount,
            operation.isToBitcoin,
            operation.operationTime,
            operation.completed,
            operation.completionTime,
            operation.txHash,
            operationValidationCounts[operationId]
        );