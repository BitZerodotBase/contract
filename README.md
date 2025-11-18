<div align="center">

<img src="https://avatars.githubusercontent.com/u/236363013?v=4" alt="BitZero Logo" width="120" />

# 🪩 BitZero Ecosystem  
### Smart Contracts on Base Network

![Network](https://img.shields.io/badge/Network-Base-blue)
![Token](https://img.shields.io/badge/Token-$BIT-purple)
![License](https://img.shields.io/badge/License-MIT-green)
![Language](https://img.shields.io/badge/Solidity-0.8.x-black)
![Status](https://img.shields.io/badge/Status-Live%20on%20Base-success)

*Transparent. Secure. Community-Driven.*

</div>

---

## 🧠 About BitZero

**BitZero** is a community-first ecosystem built on the **Base Network**, designed to empower holders through **staking**, **governance**, and **decentralized growth**.

This repository contains the **core smart contracts** that power:
- **BitZero Token ($BIT)** — the main ERC-20 token of the ecosystem  
- **BitStake** — staking and reward distribution mechanism  
- **BitZero DAO** — decentralized governance and treasury management
- **BitZero Node** — **Manages the registration and operational integrity of network nodes.**  
- **Validator Registry** — **Maintains the official, on-chain list of authorized and sanctioned validators.**   

---

## 🧩 Smart Contracts Overview

| Contract | File | Description |
|-----------|------|-------------|
| **BitZero Token** | `bitzero.sol` | ERC-20 token contract for $BIT — the native token of the BitZero ecosystem. |
| **BitStake** | `bitstakev2.sol` | Enables staking of $BIT and distributes rewards to participants based on a defined emission schedule. |
| **BitZero DAO** | `bitzerodaov2.sol` | Governance contract that manages proposals, voting, and controls the treasury via a timelock mechanism. |
| **BitZero Node** | `bitnodev2.sol` | Contract defining the operational requirements, staking deposits, and reward flow for network nodes. |
| **Validator Registry** | `ValidatorRegistry.sol` | Stores the verifiable list of active validators and manages the logic for slashing or penalizing bad actors. |

---

## 🌐 Base Mainnet Deployments

| Contract | Address | Description |
|-----------|----------|-------------|
| **BitZero Token ($BIT)** | [`0x853c1a7587413262a0a7dc2526a8ad62497a56c0`](https://basescan.org/address/0x853c1a7587413262a0a7dc2526a8ad62497a56c0) | Core ERC-20 token contract |
| **BitStake** | [`0x84140D993d4BDC23F1A2B18c1220FAC7cab8276e`](https://basescan.org/address/0x84140D993d4BDC23F1A2B18c1220FAC7cab8276e) | Staking and reward distribution contract |
| **BitZero DAO** | [`0x17BEAfbF0dc0419719A88F7F0e20265B5a6676A7`](https://basescan.org/address/0x17BEAfbF0dc0419719A88F7F0e20265B5a6676A7) | Governance and treasury control contract |
| **BitZero Node** | [0x45b7b7eFfF2055B9F9aBC62bB0166712d5308B7f](https://basescan.org/address/0x45b7b7eFfF2055B9F9aBC62bB0166712d5308B7f) | Manages node operations and deposits. |
| **Validator Registry** | [0xD986315888dcdF8B5af1B8005623A6D7C9F47aE6](https://basescan.org/address/0xD986315888dcdF8B5af1B8005623A6D7C9F47aE6) | Maintains the list of validated network participants. |

---

## ⚙️ Features

- 🧱 **ERC-20 Standard** — Fully compatible with Ethereum & Base ecosystem  
- 💰 **Staking Rewards** — Incentivized participation through BitStake  
- 🗳 **DAO Governance** — Community-driven decisions for protocol upgrades  
- 🔒 **Transparency & Security** — Open-source, verifiable smart contracts  
- ⚡ **Low-Cost Transactions** — Powered by Base Layer-2 scalability

---

## 🪙 Token Details

| Parameter | Value |
|------------|--------|
| **Name** | BitZero |
| **Ticker** | BIT |
| **Chain** | Base |
| **Standard** | ERC-20 |
| **Decimals** | 18 |
| **Total Supply** | 10,000,000,000 BIT |

---

## 📦 Local Deployment (Developers)

```bash
# Install Hardhat
npm install -g hardhat

# Compile contracts
npx hardhat compile

# Deploy (update config before running)
npx hardhat run scripts/deploy.js --network base
