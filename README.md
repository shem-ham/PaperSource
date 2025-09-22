# PaperSource

A comprehensive supply chain tracking smart contract for paper production and sustainable forestry verification built on the Stacks blockchain using Clarity.

## Overview

PaperSource enables complete transparency and traceability in the paper production supply chain, from forest origin through manufacturing to final delivery. The contract ensures sustainable forestry practices are verified and maintained throughout the entire production process.

## Features

- **Forest Registration**: Register and track sustainable forests with certification details
- **Batch Tracking**: Complete lifecycle tracking of paper batches from harvest to delivery
- **Supply Chain Stages**: Six-stage tracking system (Harvested → Processed → Manufactured → Quality Checked → Shipped → Delivered)
- **Quality Assurance**: Comprehensive quality control with moisture content, strength rating, and contamination level tracking
- **Role-Based Access**: Secure role assignments for harvesters, processors, manufacturers, inspectors, and shippers
- **Sustainability Verification**: Real-time verification of forest sustainability status for each batch
- **Audit Trail**: Complete immutable history of all batch movements and updates

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0
- **Testing Framework**: Vitest with Clarinet SDK

## Supply Chain Stages

1. **HARVESTED** (Stage 1): Initial wood material harvesting from registered forest
2. **PROCESSED** (Stage 2): Raw material processing into pulp
3. **MANUFACTURED** (Stage 3): Paper manufacturing from processed pulp
4. **QUALITY-CHECKED** (Stage 4): Quality assurance and testing
5. **SHIPPED** (Stage 5): Product shipment to destination
6. **DELIVERED** (Stage 6): Final delivery confirmation

## Installation

### Prerequisites

- Node.js (v16 or higher)
- Clarinet CLI
- Stacks wallet for deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd PaperSource
```

2. Install dependencies:
```bash
cd PaperSource_contract
npm install
```

3. Initialize Clarinet project (if needed):
```bash
clarinet integrate
```

## Usage Examples

### Registering a Forest

```clarity
(contract-call? .PaperSource register-forest
  "Amazon Sustainable Forest"
  "Amazon Basin, Brazil"
  "FSC-Certified"
  u50000  ;; 50,000 hectares
  true)   ;; is sustainable
```

### Creating a Paper Batch

```clarity
(contract-call? .PaperSource create-batch
  u1          ;; forest-id
  u100        ;; quantity in tons
  "cardboard") ;; paper type
```

### Updating Batch Stage

```clarity
(contract-call? .PaperSource update-batch-stage
  u1                                    ;; batch-id
  u2                                    ;; new stage (PROCESSED)
  (some "Processed into high-quality pulp")  ;; notes
  (some "Processing Plant A, Location"))     ;; location
```

### Recording Quality Check

```clarity
(contract-call? .PaperSource record-quality-check
  u1      ;; batch-id
  true    ;; passed quality check
  u875    ;; moisture content (8.75%)
  u8      ;; strength rating (1-10 scale)
  u50     ;; contamination level (ppm)
  (some "Meets all quality standards"))
```

## Contract Functions

### Public Functions

#### Forest Management
- `register-forest`: Register a new sustainable forest (Owner only)
- `get-forest`: Retrieve forest information by ID

#### Batch Management
- `create-batch`: Create new paper batch from forest materials
- `update-batch-stage`: Update batch to next supply chain stage
- `assign-batch-role`: Assign supply chain roles to users (Owner only)
- `get-batch`: Retrieve batch information by ID

#### Quality Control
- `record-quality-check`: Record quality inspection results
- `get-quality-check`: Retrieve quality check data for batch

#### User Management
- `authorize-user`: Authorize users for specific roles (Owner only)
- `get-user-authorization`: Check user role authorization

### Read-Only Functions

#### Information Retrieval
- `get-batch-stage-history`: Get historical stage data for batch
- `is-forest-sustainable`: Check forest sustainability status
- `get-batch-sustainability`: Check batch sustainability based on source forest
- `get-next-batch-id`: Get next available batch ID
- `get-next-forest-id`: Get next available forest ID

## Data Structures

### Forest Data
```clarity
{
  name: (string-ascii 100),
  location: (string-ascii 200),
  certification: (string-ascii 50),
  owner: principal,
  total-area: uint,
  is-sustainable: bool,
  created-at: uint
}
```

### Paper Batch Data
```clarity
{
  forest-id: uint,
  harvest-date: uint,
  current-stage: uint,
  quantity: uint,
  paper-type: (string-ascii 50),
  processor: (optional principal),
  manufacturer: (optional principal),
  quality-inspector: (optional principal),
  shipper: (optional principal),
  final-destination: (optional (string-ascii 200)),
  created-by: principal,
  created-at: uint,
  last-updated: uint
}
```

### Quality Check Data
```clarity
{
  inspector: principal,
  passed: bool,
  moisture-content: uint,
  strength-rating: uint,
  contamination-level: uint,
  notes: (optional (string-ascii 500)),
  timestamp: uint
}
```

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage and cost analysis:

```bash
npm run test:report
```

Watch mode for continuous testing:

```bash
npm run test:watch
```

## Deployment

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract PaperSource contracts/PaperSource.clar
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments apply --network testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy using Clarinet:
```bash
clarinet deployments apply --network mainnet
```

## Security Considerations

### Access Control
- Contract owner has administrative privileges for forest registration and user authorization
- Role-based permissions for supply chain operations
- Quality inspectors have specific authorization for quality checks

### Data Integrity
- Immutable audit trail for all batch movements
- Stage progression validation (cannot skip stages or move backwards)
- Forest sustainability verification for all batches

### Error Handling
The contract implements comprehensive error codes:
- `ERR-NOT-AUTHORIZED` (u100): Unauthorized access attempt
- `ERR-INVALID-BATCH` (u101): Invalid batch parameters
- `ERR-BATCH-ALREADY-EXISTS` (u102): Duplicate batch creation
- `ERR-FOREST-NOT-FOUND` (u103): Referenced forest does not exist
- `ERR-INVALID-STAGE` (u104): Invalid stage transition
- `ERR-BATCH-NOT-FOUND` (u105): Referenced batch does not exist

### Best Practices
- Always verify forest sustainability before creating batches
- Maintain proper role assignments throughout the supply chain
- Record detailed notes and locations for audit purposes
- Implement additional business logic validation as needed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

[Specify your license here]

## Support

For technical support or questions about the PaperSource smart contract, please refer to the Stacks documentation or create an issue in this repository.