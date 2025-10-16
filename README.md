# EARN Vault

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Forge](https://img.shields.io/badge/forge-v1.0.0-blue.svg?style=for-the-badge)
![Solc](https://img.shields.io/badge/solc-v0.8.26-blue.svg?style=for-the-badge)
[![GitHub License](https://img.shields.io/github/license/earn-labs/earn-vault?style=for-the-badge)](https://github.com/earn-labs/earn-vault/blob/master/LICENSE)

---

## About EARN Vault

EARN Vault is a secure, extensible smart contract system developed by [EARN Labs](https://earnlabs.org) for managing tokenized assets and rewards. The vault enables owners to deposit, withdraw, and earn additional rewards through reflection mechanisms. It supports both token approvals and direct transfers, ensuring accurate accounting for all deposit types.

---

## Features

- Secure deposit and withdrawal of ERC-20 tokens
- Reflection-based reward accumulation
- Flexible deposit methods (approval or direct transfer)
- Designed for extensibility and integration

---

## Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/earn-labs/earn-vault.git
cd earn-vault
make install
```

---

## Configuration

Before running commands, create a `.env` file with the following variables:

```env
# Network configs
RPC_LOCALHOST="http://127.0.0.1:8545"
RPC_TEST=<rpc url>
RPC_MAIN=<rpc url>
ETHERSCAN_KEY=<api key>

# Deployment accounts
ACCOUNT_NAME="account name"
ACCOUNT_ADDRESS="account address"
```

Update chain IDs in `script/HelperConfig.s.sol` as needed:
- Ethereum: 1 | Sepolia: 11155111
- Base: 8453 | Base Sepolia: 84532
- BSC: 56 | BSC Testnet: 97

---

## Usage

### Run Tests

```bash
forge test
```

### Deploy to Testnet

```bash
make deploy-testnet
```

### Deploy to Mainnet

```bash
make deploy-mainnet
```

---

## Deployments

- **Sepolia Testnet:** [0x47ad28668b541cd0de8eb11e3090fb37e69f8a60](https://sepolia.etherscan.io/address/0x47ad28668b541cd0de8eb11e3090fb37e69f8a60)
- **Ethereum Mainnet:** [0xcb44a97a62fc7c087c4cc9024dd5a9d3eb9cf81e](https://etherscan.io/address/0xcb44a97a62fc7c087c4cc9024dd5a9d3eb9cf81e)

---

## Contributing

We welcome contributions from the community! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add YourFeature'`)
4. Push to your branch (`git push origin feature/YourFeature`)
5. Open a pull request

For suggestions or issues, please open an issue with the appropriate label.

---

## Authors & Maintainers

**EARN Labs**  
Website: [earnlabs.org](https://earnlabs.org)

**Lead Maintainer:**  
Nadina Oates  
[Website](https://trashpirate.io) | [Twitter](https://twitter.com/0xTrashPirate) | [GitHub](https://github.com/trashpirate) | [LinkedIn](https://linkedin.com/in/nadinaoates)

---

## License

This project is licensed under the MIT License.  
Copyright © 2025 [EARN Labs](https://earnlabs.org)

