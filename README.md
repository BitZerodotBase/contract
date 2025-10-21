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
- 🪙 **BitZero Token ($BIT)** — the main ERC-20 token of the ecosystem  
- 💎 **BitStake** — staking and reward distribution mechanism  
- 🗳 **BitZero DAO** — decentralized governance and treasury management  

---

## 🧩 Smart Contracts Overview

| Contract | File | Description |
|-----------|------|-------------|
| **BitZero Token** | `bitzero.sol` | ERC-20 token contract for $BIT — the native token of the BitZero ecosystem. |
| **BitStake** | `bitstake.sol` | Enables staking of $BIT and distributes rewards to participants. |
| **BitZero DAO** | `bitzerodao.sol` | Governance contract that manages proposals, voting, and treasury control. |

---

## 🌐 Base Mainnet Deployments

| Contract | Address | Description |
|-----------|----------|-------------|
| **BitZero Token ($BIT)** | [`0x853c1a7587413262a0a7dc2526a8ad62497a56c0`](https://basescan.org/address/0x853c1a7587413262a0a7dc2526a8ad62497a56c0) | Core ERC-20 token contract |
| **BitStake** | [`0x1f496658EFC517c58A4aC365157838DC155e0D15`](https://basescan.org/address/0x1f496658EFC517c58A4aC365157838DC155e0D15) | Staking and reward distribution contract |
| **BitZero DAO** | [`0xdd7BFA32deADbb8d4b1084d8ec2acE883657b1d1`](https://basescan.org/address/0xddBFA32deADbb8d4b1084d8ec2acE883657b1d1) | Governance and treasury contract |

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
