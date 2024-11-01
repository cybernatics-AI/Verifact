# Digital Credential Verification Smart Contract

A secure and efficient smart contract implementation for issuing, verifying, and managing digital credentials on the Stacks blockchain.

## Overview

This smart contract provides a comprehensive system for managing digital credentials with features including:

- Credential issuance and verification
- Issuer management
- Credential revocation
- Ownership transfer
- Expiration management
- Metadata updates

## Features

### Credential Management
- Issue new digital credentials
- Verify credential validity
- Revoke credentials
- Transfer credential ownership
- Update credential metadata
- Track credential versions
- Handle credential expiration

### Issuer Management
- Add and remove authorized issuers
- Update issuer status
- Track issuer statistics
- Manage issuer credentials count

### Security Features
- Owner-only administrative functions
- Authorization checks
- Input validation
- Expiration validation
- Revocation tracking
- Event logging

## Contract Functions

### Administrative Functions

```clarity
(define-public (add-issuer (issuer principal) (name (string-utf8 64))))
(define-public (remove-issuer (issuer principal)))
(define-public (update-issuer-status (issuer principal) (active bool)))
```

### Credential Management Functions

```clarity
(define-public (issue-credential 
    (recipient principal)
    (credential-type (string-utf8 256))
    (expiry-date (optional uint))
    (metadata-hash (string-ascii 64))))

(define-public (revoke-credential (credential-id uint)))

(define-public (transfer-credential-ownership 
    (credential-id uint) 
    (new-owner principal)))

(define-public (update-credential-metadata 
    (credential-id uint)
    (new-metadata-hash (string-ascii 64))))
```

### Read-Only Functions

```clarity
(define-read-only (get-credential-by-id (credential-id uint)))
(define-read-only (verify-credential (credential-id uint)))
(define-read-only (get-issuer-status (issuer principal)))
(define-read-only (get-recipient-credentials 
    (recipient principal) 
    (credential-type (string-utf8 256))))
(define-read-only (get-issuer-stats (issuer principal)))
(define-read-only (is-valid-credential (credential-id uint)))
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner-only operation |
| u101 | Not authorized |
| u102 | Already exists |
| u103 | Invalid credential |
| u104 | Credential revoked |
| u105 | Invalid parameters |
| u106 | Credential expired |
| u107 | Self-transfer not allowed |
| u108 | Invalid future date |
| u109 | Event error |
| u110 | Invalid name |
| u111 | Invalid metadata |
| u112 | Invalid expiry |

## Events

The contract emits the following events:

- `issuer-added`
- `issuer-removed`
- `issuer-updated`
- `credential-issued`
- `credential-revoked`
- `credential-updated`
- `credential-transfer`

## Data Structures

### Credential
```clarity
{
    recipient: principal,
    issuer: principal,
    credential-type: (string-utf8 256),
    issue-date: uint,
    expiry-date: (optional uint),
    metadata-hash: (string-ascii 64),
    revoked: bool,
    version: uint
}
```

### Issuer
```clarity
{
    active: bool,
    name: (string-utf8 64),
    added-at: uint,
    credential-count: uint
}
```

## Usage Examples

### Adding a New Issuer
```clarity
(contract-call? .verify-contract add-issuer 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
    u"Example Institution")
```

### Issuing a Credential
```clarity
(contract-call? .verify-contract issue-credential
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    u"degree"
    (some u144540)
    "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi")
```

### Verifying a Credential
```clarity
(contract-call? .verify-contract verify-credential u1)
```

## Security Considerations

1. Only the contract owner can add or remove issuers
2. Only authorized issuers can issue credentials
3. Only credential owners can transfer ownership
4. Only issuers can revoke their issued credentials
5. Expired credentials are automatically invalidated
6. Input validation prevents invalid data entry
7. Event logging provides audit trail

## Development

### Prerequisites
- Clarity language knowledge
- Stacks blockchain understanding
- Clarinet for testing

### Testing
Use Clarinet to run the test suite:
```bash
clarinet test
```
