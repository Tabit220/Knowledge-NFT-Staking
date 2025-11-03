# 🎓 Knowledge NFT Staking

> 🚀 Revolutionizing education through blockchain-powered incentives

A smart contract that enables students to stake NFTs representing completed educational modules, while rewarding educators with tokens when their content is reused across different schools.

## 🌟 Features

- 📚 **Module Creation**: Educators can create educational modules with custom reward rates
- 🎯 **NFT Staking**: Students stake NFTs of completed modules to earn rewards
- 💰 **Automatic Rewards**: Educators earn tokens when their modules are used by other schools
- 🏫 **School Usage Tracking**: Track module usage across different educational institutions
- 🔒 **Minimum Stake Period**: Ensures commitment with a minimum staking duration
- 📊 **Comprehensive Stats**: View user statistics, educator earnings, and module performance

## 🛠️ Contract Functions

### 📝 Module Management

#### `create-module`
```clarity
(create-module title description reward-per-use)
```
Creates a new educational module with specified title, description, and reward rate.

#### `deactivate-module`
```clarity
(deactivate-module module-id)
```
Deactivates a module (only by the educator who created it).

### 🎯 Staking Operations

#### `stake-nft`
```clarity
(stake-nft nft-contract token-id module-id)
```
Stake an NFT representing completion of a specific module.

#### `unstake-nft`
```clarity
(unstake-nft nft-contract token-id)
```
Unstake an NFT and claim accumulated rewards (after minimum period).

### 🏫 School Usage

#### `use-module`
```clarity
(use-module module-id school)
```
Record usage of a module by a school, triggering educator rewards.

### 💰 Rewards Management

#### `add-rewards-to-pool`
```clarity
(add-rewards-to-pool amount)
```
Add tokens to the rewards pool (contract owner only).

## 📖 Read-Only Functions

### 📊 Information Retrieval

- `get-module-info(module-id)` - Get module details
- `get-stake-info(nft-contract, token-id)` - Get staking information
- `get-user-stats(user)` - Get user staking statistics
- `get-educator-stats(educator)` - Get educator earnings and module count
- `get-module-usage(module-id, school)` - Get usage stats for a module by school
- `get-next-module-id()` - Get the next available module ID
- `get-total-rewards-pool()` - Get total rewards pool amount
- `get-token-balance(user)` - Get user's token balance

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- Stacks wallet for testing

### Installation
1. Clone this repository
2. Navigate to the project directory
3. Run `clarinet check` to verify contract compilation
4. Deploy using `clarinet deploy`

### Usage Examples

#### 🎓 As an Educator
```bash
# Create a new module
(contract-call? .Knowledge-NFT-Staking create-module "Blockchain Basics" "Introduction to blockchain technology" u100)

# Check your stats
(contract-call? .Knowledge-NFT-Staking get-educator-stats 'SP1234...)
```

#### 🎯 As a Student
```bash
# Stake your completion NFT
(contract-call? .Knowledge-NFT-Staking stake-nft .my-nft-contract u1 u1)

# Check your staking stats
(contract-call? .Knowledge-NFT-Staking get-user-stats 'SP1234...)

# Unstake after minimum period
(contract-call? .Knowledge-NFT-Staking unstake-nft .my-nft-contract u1)
```

#### 🏫 As a School
```bash
# Use an educational module
(contract-call? .Knowledge-NFT-Staking use-module u1 'SP-SCHOOL-ADDRESS)

# Check module usage
(contract-call? .Knowledge-NFT-Staking get-module-usage u1 'SP-SCHOOL-ADDRESS)
```

## ⚡ Key Benefits

- 🎯 **Incentivizes Quality**: Educators are rewarded for creating valuable content
- 🔄 **Promotes Reuse**: Rewards educators when content is used across schools
- 💎 **Student Engagement**: Students earn tokens by completing and staking modules
- 📈 **Transparent Tracking**: All usage and rewards are recorded on-chain
- 🌐 **Scalable**: Works across multiple educational institutions

## 🔧 Technical Details

- **Token**: `knowledge-token` (fungible token for rewards)
- **Minimum Stake Period**: 144 blocks (~24 hours)
- **Reward Distribution**: Automatic upon module usage
- **NFT Compatibility**: Works with any NFT following the standard trait

## 🛡️ Security Features

- ✅ Owner verification for NFT staking
- ✅ Minimum staking period enforcement
- ✅ Module activation status checks
- ✅ Authorization checks for module management
- ✅ Balance validation for all operations

## 📊 Constants & Error Codes

```clarity
ERR_UNAUTHORIZED (u100)     - Unauthorized access
ERR_NOT_FOUND (u101)        - Resource not found
ERR_ALREADY_STAKED (u102)   - NFT already staked
ERR_NOT_STAKED (u103)       - NFT not currently staked
ERR_INVALID_AMOUNT (u104)   - Invalid amount specified
ERR_INSUFFICIENT_BALANCE (u105) - Insufficient token balance
```

## 🤝 Contributing

Contributions are welcome! Please ensure all changes pass `clarinet check` before submitting.

## 📄 License

This project is open source and available under the MIT License.

---

*Built with ❤️ for the future of education*
