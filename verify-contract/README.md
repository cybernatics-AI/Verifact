# Digital Credential Verification System

A Clarity smart contract for managing and verifying digital credentials on the Stacks blockchain.

## Overview

This smart contract implements a system for issuing, managing, and verifying digital credentials. It allows authorized issuers to create credentials, recipients to manage their credentials, and provides functionality for credential verification.

## Features

- Issuer management (add, remove, update status)
- Credential issuance
- Credential revocation
- Credential ownership transfer
- Credential verification
- Metadata updates for credentials
- Event logging for major actions

## Key Functions

### Administrative

- `add-issuer`: Add a new authorized issuer
- `remove-issuer`: Remove an existing issuer
- `update-issuer-status`: Update the active status of an issuer

### Credential Management

- `issue-credential`: Issue a new credential to a recipient
- `revoke-credential`: Revoke an existing credential
- `transfer-credential-ownership`: Transfer ownership of a credential to a new recipient
- `update-credential-metadata`: Update the metadata of an existing credential

### Read-only Functions

- `get-credential-by-id`: Retrieve credential details by ID
- `verify-credential`: Check if a credential is valid and not revoked
- `get-issuer-status`: Check the status of an issuer
- `get-recipient-credentials`: Get a list of credentials for a recipient
- `get-issuer-stats`: Retrieve statistics for an issuer
- `is-valid-credential`: Check if a credential is valid, not revoked, and not expired

## Data Structures

- `Credentials`: Stores credential data
- `Issuers`: Stores issuer information
- `RecipientCredentials`: Maps recipients to their credentials
- `Events`: Logs important events in the system

## Error Handling

The contract includes various error codes for different scenarios, ensuring proper validation and error reporting.

## Usage

To use this contract, deploy it to the Stacks blockchain and interact with it using the provided public functions. Ensure that only authorized principals perform administrative actions.

## Security Considerations

- Only the contract owner can add or remove issuers
- Credentials can only be revoked by their issuer
- Credential transfers require the current owner's authorization
- Expiry dates and revocation status are checked for credential validity

## Events

The contract emits events for major actions, allowing for easy tracking and auditing of system activities.
