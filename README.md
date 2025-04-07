# LendX - Decentralized Cross-Chain Lending Platform

LendX is a decentralized, cross-chain lending platform built on the Sui blockchain ecosystem that enables users to access stablecoins without selling their crypto holdings. The platform preserves long-term asset positions, avoids triggering taxable events, and leverages real-time data for robust risk management.

## 🌟 Key Features

- **Cross-Chain Lending**: Access liquidity across multiple blockchain networks
- **Asset Preservation**: Maintain crypto exposure while accessing stablecoins
- **Real-Time Risk Management**: Dynamic pricing and collateral monitoring
- **Tax Efficiency**: Avoid taxable events from asset liquidation
- **High Performance**: Built on Sui blockchain for fast and secure operations

## 🏗️ Architecture & Components

### Core Technologies

- **Sui Blockchain**: High-performance blockchain platform
- **Pyth Network**: Real-time price feeds for accurate collateral valuation
- **Wormhole**: Cross-chain asset interoperability
- **Walrus**: Secure on-chain storage solution
- **TwitterAIClient**: AI-powered social engagement and monitoring

### System Components

1. **Liquidity Providers (LPs)**

   - Deposit stablecoins (e.g., USDC) into liquidity pools
   - Earn interest from borrower repayments
   - Automated interest accrual and fee management

2. **Borrowers & Collateral Management**

   - Lock crypto assets as collateral
   - Access stablecoins without selling holdings
   - Maintain long-term investment positions

3. **Smart Contracts**
   - Collateral management and liquidation
   - Interest calculation and repayment
   - Automated fee structure

## 🚀 Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MongoDB (for backend)
- Sui CLI (for smart contract deployment)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/your-org/lendx.git
cd lendx
```

2. Install frontend dependencies:

```bash
npm install
```

3. Install backend dependencies:

```bash
cd backend
npm install
```

4. Set up environment variables:

```bash
# Frontend (.env.local)
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXT_PUBLIC_SUI_NETWORK=testnet

# Backend (.env)
PORT=5000
MONGODB_URI=mongodb://localhost:27017/lendx
NODE_ENV=development
```

### Running the Application

1. Start the backend server:

```bash
cd backend
npm run dev
```

2. Start the frontend development server:

```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000) in your browser

## 🔒 Security & Risk Management

- Real-time collateral monitoring via Pyth Network
- Automated liquidation triggers
- Secure cross-chain asset management through Wormhole
- Immutable on-chain storage with Walrus
- Regular security audits and compliance checks

## 📊 Use Cases

### For Borrowers

- Access liquidity without selling crypto assets
- Maintain long-term investment positions
- Tax-efficient borrowing
- Flexible fund usage (yield farming, expenses)

### For Liquidity Providers

- Earn attractive yields
- Benefit from robust risk management
- Participate in a growing ecosystem

## 🛠️ Technical Stack

### Frontend

- Next.js
- TypeScript
- Tailwind CSS
- Sui SDK

### Backend

- Node.js
- Express
- MongoDB
- TypeScript

### Blockchain

- Sui
- Pyth Network
- Wormhole
- Walrus

## 📈 Future Enhancements

- Expanded asset support
- Enhanced user interface
- Advanced analytics
- Regulatory compliance updates
- Additional blockchain integrations

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

For any queries or support, please reach out to our team at support@lendx.io
