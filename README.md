# Parametric Insurance Protocol

## Overview

An automated insurance platform that uses external data feeds to trigger instant payouts for parametric insurance policies covering natural disasters, flight delays, and weather-related events. Policyholders receive immediate compensation when predefined conditions are met, eliminating lengthy claims processes and reducing administrative costs through smart contract automation.

## Architecture

This project implements a robust blockchain-based solution using Clarity smart contracts on the Stacks blockchain. The architecture follows modern decentralized application principles with emphasis on security, transparency, and user experience.

### Core Components

The system consists of multiple interconnected smart contracts that work together to provide comprehensive functionality:

- **Policy Management Layer**: Handles core insurance policy creation and management
- **Oracle Integration Layer**: Manages external data feeds and validation
- **Payout Processing Layer**: Automates claim evaluation and compensation distribution
- **Security Layer**: Implements access controls and validation mechanisms

### Technology Stack

- **Blockchain**: Stacks blockchain with Clarity smart contracts
- **Development Framework**: Clarinet for local development and testing
- **Language**: Clarity for smart contract development
- **Testing**: Built-in Clarinet testing framework
- **Deployment**: Automated deployment pipeline

## Smart Contracts

This project includes multiple smart contracts designed to work together seamlessly:

1. **Policy Manager**: Creates and manages parametric insurance policies, processes premium payments, defines trigger conditions for automatic payouts, and maintains policyholder records and coverage details.

2. **Oracle Processor**: Integrates with external data oracles to monitor trigger conditions, validates data sources for accuracy, executes automatic claim payouts when conditions are met, and manages dispute resolution processes.

Each contract is thoroughly tested and follows Clarity best practices for security and efficiency.

## Features

### Parametric Insurance Benefits
- **Instant Payouts**: Automated claim processing based on predefined trigger conditions
- **Transparency**: All policy terms and trigger conditions are publicly verifiable on blockchain
- **Reduced Costs**: Elimination of manual claim assessment reduces administrative overhead
- **Global Accessibility**: Decentralized platform accessible to users worldwide
- **Immutable Records**: All policies and transactions permanently recorded on blockchain

### Supported Coverage Types
- **Natural Disasters**: Earthquake, hurricane, flood, and wildfire coverage
- **Flight Delays**: Automated compensation for delayed or cancelled flights  
- **Weather Events**: Temperature, rainfall, and drought-based agricultural insurance
- **Custom Parameters**: Flexible framework for creating new parametric products

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed locally
- Node.js 14+ for development tools
- Git for version control

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dayosamuel705/parametric-insurance-protocol.git
   cd parametric-insurance-protocol
   ```

2. Install dependencies:
   ```bash
   clarinet requirements
   ```

3. Run tests:
   ```bash
   clarinet test
   ```

### Development

To start developing:

1. Run local blockchain environment:
   ```bash
   clarinet integrate
   ```

2. Deploy contracts locally:
   ```bash
   clarinet deploy --network=devnet
   ```

3. Interact with contracts using Clarinet console:
   ```bash
   clarinet console
   ```

## Testing

The project includes comprehensive tests for all smart contracts:

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/policy-manager_test.ts

# Run with coverage
clarinet test --coverage
```

## Deployment

### Testnet Deployment

1. Configure testnet settings in `Clarinet.toml`
2. Deploy to testnet:
   ```bash
   clarinet deploy --network=testnet
   ```

### Mainnet Deployment

1. Update mainnet configuration
2. Deploy to mainnet:
   ```bash
   clarinet deploy --network=mainnet
   ```

## Usage Examples

### Creating a Flight Delay Policy

```clarity
;; Create a new flight delay policy
(contract-call? .policy-manager create-policy
  "flight-delay"
  u100000000  ;; premium in microSTX
  u500000000  ;; coverage amount
  { flight-number: "AA123", departure-time: u1640995200 }
)
```

### Processing Oracle Data

```clarity
;; Submit weather data for processing
(contract-call? .oracle-processor submit-data
  "weather-station-001"
  { temperature: u85, rainfall: u0 }
  u1640995200
)
```

## API Documentation

### Policy Manager Contract

#### Public Functions
- `create-policy`: Create a new parametric insurance policy
- `pay-premium`: Process premium payment for existing policy
- `update-policy`: Modify policy parameters (admin only)
- `get-policy-info`: Retrieve policy details

#### Read-Only Functions
- `get-policy`: Get policy information by ID
- `get-user-policies`: Get all policies for a user
- `calculate-premium`: Calculate premium for given parameters

### Oracle Processor Contract

#### Public Functions
- `register-oracle`: Register new data source
- `submit-data`: Submit data for policy evaluation
- `trigger-payout`: Process automatic payout when conditions met
- `dispute-claim`: Initiate dispute resolution process

#### Read-Only Functions
- `get-oracle-data`: Retrieve latest data from specific oracle
- `validate-trigger`: Check if payout conditions are met

## Contributing

We welcome contributions to improve this project:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Clarity coding standards
- Write comprehensive tests for new features
- Update documentation for any changes
- Ensure all tests pass before submitting PRs
- Add inline comments for complex logic
- Maintain backward compatibility when possible

## Security

Security is our top priority. The contracts have been designed with:

- **Input Validation**: All user inputs are thoroughly validated
- **Access Controls**: Role-based permissions for administrative functions
- **Safe Mathematics**: Overflow and underflow protection
- **Oracle Security**: Data source validation and dispute mechanisms
- **Audit Trail**: Complete transaction history for all operations

### Security Considerations

- All premium calculations include overflow protection
- Oracle data is validated through multiple sources where possible  
- Emergency pause functionality available for critical issues
- Multi-signature requirements for high-value operations

## Roadmap

Future enhancements planned:

- **Multi-Oracle Support**: Integration with multiple data providers for enhanced reliability
- **Advanced Analytics**: Historical data analysis and predictive modeling
- **Mobile Application**: Native mobile app for policy management
- **Cross-Chain Support**: Integration with other blockchain networks
- **AI Integration**: Machine learning for risk assessment and pricing
- **Governance Token**: Community governance for protocol parameters

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:

- Create an issue in the GitHub repository
- Join our community discussions
- Contact the development team at support@parametric-insurance.com
- Follow us on Twitter [@ParametricProtocol](https://twitter.com/ParametricProtocol)

## Acknowledgments

- Hiro Systems for the Stacks blockchain and Clarinet development tools
- The Clarity smart contract community for guidance and best practices
- Weather data providers and oracle network partners
- Insurance industry advisors and regulatory consultants

---

Built with ❤️ using Clarity and the Stacks blockchain. Making insurance more accessible, transparent, and efficient for everyone.