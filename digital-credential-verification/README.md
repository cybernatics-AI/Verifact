# 📜 Digital Credential Verification System (DCVS) - Stacks Blockchain

The **Digital Credential Verification System** is a Clarity-based smart contract on the **Stacks blockchain** that allows decentralized **issuance, management, verification, and transfer of digital credentials**. The system is designed for universities, certifying bodies, professional organizations, and other trusted entities to issue credentials verifiably and immutably.

---

## 🚀 Features

* ✅ **Issuer Management**
  Add, remove, and update credential issuers by contract owner.

* 🎓 **Credential Issuance**
  Issuers can issue credentials to recipients with metadata, expiration, and versioning.

* 🔄 **Credential Transfer**
  Credential holders can transfer ownership (e.g., in case of account change).

* ❌ **Credential Revocation**
  Issuers can revoke credentials that are no longer valid.

* 🔍 **Verification Functions**
  Verify whether a credential is valid, revoked, or expired.

* 🧾 **Event Logging**
  All critical actions emit events, which are stored on-chain for traceability.

* 🔐 **Access Control**
  Contract ensures that only authorized issuers and the contract owner can perform restricted actions.

---

## 📦 Data Structures

### Issuers Map

| Field              | Type              | Description                             |
| ------------------ | ----------------- | --------------------------------------- |
| `active`           | `bool`            | Whether issuer is currently authorized. |
| `name`             | `string-utf8(64)` | Issuer name.                            |
| `added-at`         | `uint`            | Block height of addition.               |
| `credential-count` | `uint`            | Number of credentials issued.           |

---

### Credentials Map

| Field             | Type               | Description                          |
| ----------------- | ------------------ | ------------------------------------ |
| `recipient`       | `principal`        | Address of credential owner.         |
| `issuer`          | `principal`        | Address of issuer.                   |
| `credential-type` | `string-utf8(256)` | Type of credential (e.g., degree).   |
| `issue-date`      | `uint`             | Block height at issuance.            |
| `expiry-date`     | `optional uint`    | Optional expiration block height.    |
| `metadata-hash`   | `string-ascii(64)` | Metadata hash (IPFS or off-chain).   |
| `revoked`         | `bool`             | Whether credential has been revoked. |
| `version`         | `uint`             | Incremental version number.          |

---

### Events Map

| Field           | Type              | Description             |
| --------------- | ----------------- | ----------------------- |
| `event-type`    | `string-utf8(32)` | Type of event.          |
| `credential-id` | `optional uint`   | Credential ID involved. |
| `principal`     | `principal`       | Actor of the event.     |
| `timestamp`     | `uint`            | Block height of event.  |

---

### RecipientCredentials Map

Maps each recipient and credential-type combination to a list of credential IDs.

---

## 🛠 Public Functions

### 🔧 Admin

* `add-issuer(principal, name)` – Add new issuer.
* `remove-issuer(principal)` – Remove issuer.
* `update-issuer-status(principal, bool)` – Activate/deactivate issuer.

### 🧾 Credential Lifecycle

* `issue-credential(recipient, type, expiry?, metadata-hash)` – Issue credential.
* `update-credential-metadata(id, metadata-hash)` – Update metadata hash and increment version.
* `revoke-credential(id)` – Revoke issued credential.
* `transfer-credential-ownership(id, new-owner)` – Transfer credential to new principal.

### 🔍 Read-Only

* `get-credential-by-id(id)` – Get full credential record.
* `verify-credential(id)` – Check if not revoked.
* `is-valid-credential(id)` – Check if valid (not revoked and not expired).
* `get-issuer-status(principal)` – Check if issuer is active.
* `get-issuer-stats(principal)` – View stats for issuer.
* `get-recipient-credentials(principal, type)` – List credential IDs by recipient and type.

---

## ✅ Validation Rules

* Credential types and metadata hashes must be non-empty and within size limits.
* Only contract owner can manage issuers.
* Only active issuers can issue or revoke credentials.
* Expiry dates (if provided) must be in the future.
* Recipients cannot transfer to themselves.
* Credential issuance and updates must pass validity checks.

---

## 📖 Events (Printable)

| Constant Name                  | Value                   |
| ------------------------------ | ----------------------- |
| `EVENT-ISSUER-ADDED`           | `"issuer-added"`        |
| `EVENT-ISSUER-REMOVED`         | `"issuer-removed"`      |
| `EVENT-ISSUER-UPDATED`         | `"issuer-updated"`      |
| `EVENT-CREDENTIAL-ISSUED`      | `"credential-issued"`   |
| `EVENT-CREDENTIAL-REVOKED`     | `"credential-revoked"`  |
| `EVENT-CREDENTIAL-UPDATED`     | `"credential-updated"`  |
| `EVENT-CREDENTIAL-TRANSFERRED` | `"credential-transfer"` |

---

## ⚠️ Error Codes

| Constant Name            | Code | Description                       |
| ------------------------ | ---- | --------------------------------- |
| `err-owner-only`         | 100  | Only contract owner can call      |
| `err-not-authorized`     | 101  | Unauthorized issuer               |
| `err-already-exists`     | 102  | Entry already exists              |
| `err-invalid-credential` | 103  | Credential not found              |
| `err-revoked`            | 104  | Credential already revoked        |
| `err-invalid-params`     | 105  | Invalid input or storage error    |
| `err-expired`            | 106  | Credential has expired            |
| `err-self-transfer`      | 107  | Recipient and sender are the same |
| `err-future-date`        | 108  | Expiry date must be in the future |
| `err-event-error`        | 109  | Event storage failed              |
| `err-invalid-name`       | 110  | Invalid issuer name               |
| `err-invalid-metadata`   | 111  | Invalid metadata hash             |

---

## 🧪 Testing Tips

* Use `clarinet` to test locally on the Stacks testnet.
* Mock block height increases to simulate expiry.
* Test boundary cases like 100 credentials per recipient/type.
* Validate issuer restrictions thoroughly.

---

## 🧱 Example Use Case Flow

1. **Admin adds issuer**
   `add-issuer('SP123...', "Harvard University")`

2. **Issuer issues credential**
   `issue-credential('SP456...', "Bachelor's Degree", some expiry, "QmXYZ...")`

3. **Recipient transfers credential**
   `transfer-credential-ownership(1, 'SP789...')`

4. **Verifier checks validity**
   `is-valid-credential(1) → true`
