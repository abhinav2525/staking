// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;




contract Staking {
    IERC20 public immutable stakingToken; // The token being staked
    IERC20 public immutable rewardToken; // The token being distributed as rewards

    address public owner;

    uint public duration; //    rewards duration
    uint public finishAt; //    rewards finish time
    uint public updatedAt; //    last update time
    uint public rewardRate; //    rewards rate
    uint public rewardPerTokenStored;   //    rewards per token stored

    mapping(address => uint) public userRewardPerTokenPaid; //    user rewards per token paid
    mapping(address => uint) public rewards;    //    rewards

    uint public totalsupply; //    total supply

    mapping(address => uint) public balanceOf; 


    uint256 private constant REWARD_PER_TOKEN_PER_DAY = 1e18; // Assuming DEFI token has 18 decimals
    uint256 private constant SECONDS_PER_DAY = 86400; // Number of seconds in a day
    uint256 private constant BLOCKS_PER_DAY = SECONDS_PER_DAY / 6; // Approximation of Ethereum blocks per day

   constructor(address _stakingToken, address _rewardToken) { 
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken); 
        rewardToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) { //    if account is not zero address
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    //    set rewards duration
    function setRewardsDuration(uint256 _duration) external onlyOwner { 
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }


    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
    require(block.timestamp >= finishAt, "Previous rewards period must be complete before starting a new one.");
    require(_amount > 0, "Cannot notify reward amount of zero.");

    // Calculate the duration in blocks instead of time to ensure rewards are distributed per block
    uint256 rewardDurationInBlocks = duration / 6; // Convert duration from seconds to number of blocks

    // Update rewardRate to reflect the amount of DEFI tokens distributed per block
    if (block.timestamp >= finishAt) {
        rewardRate = _amount / rewardDurationInBlocks;
    } else {
        // If we're still within the reward period, calculate remaining rewards and adjust
        uint256 remaining = finishAt - block.timestamp;
        uint256 leftover = remaining * rewardRate;
        rewardRate = (_amount + leftover) / rewardDurationInBlocks;
    }

    // Ensure the contract has enough tokens to pay out the rewards
    uint256 requiredRewardBalance = rewardRate * rewardDurationInBlocks;
    require(rewardToken.balanceOf(address(this)) >= requiredRewardBalance, "Insufficient rewards in contract.");

    finishAt = block.timestamp + duration;
    updatedAt = block.timestamp;
}

    
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalsupply += _amount;
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        balanceOf[msg.sender] -= _amount;
        totalsupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function lastTimeRewardApplicable() public view returns (uint256) { 
        return min(block.timestamp, finishAt);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalsupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 blocksSinceLastUpdate = (lastTimeRewardApplicable() - updatedAt) / 6; // Convert time to block count
        return rewardPerTokenStored + (blocksSinceLastUpdate * REWARD_PER_TOKEN_PER_DAY / BLOCKS_PER_DAY * 1e18 / totalsupply);
    }

    function earned(address _account) public view returns (uint256) {
        return balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account] / 1e18) + rewards[_account];
    }

    function getReward() external updateReward(msg.sender){
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}
