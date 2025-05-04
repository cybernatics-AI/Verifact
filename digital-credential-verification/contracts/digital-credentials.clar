;; Digital Credential Verification System - Core
;; Core contract with primary data structures and interfaces

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-credential (err u103))
;; ... other error constants ...

;; Define trait for other contracts to interact with this contract
(define-trait core-trait
    (
        (get-credential-by-id (uint) (response {
            recipient: principal,
            issuer: principal,
            credential-type: (string-utf8 256),
            issue-date: uint,
            expiry-date: (optional uint),
            metadata-hash: (string-ascii 64),
            revoked: bool,
            version: uint
        } uint))
        (get-credential-counter () (response uint uint))
        (increment-credential-counter () (response uint uint))
    )
)

;; Data Variables
(define-data-var credential-counter uint u0)

;; Primary data structures (kept in core for simplicity)
(define-map Credentials
    uint
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
)

;; Core read-only functions
(define-read-only (get-credential-by-id (credential-id uint))
    (match (map-get? Credentials credential-id)
        credential (ok credential)
        (err err-invalid-credential)
    )
)

;; Core credential verification logic
(define-read-only (is-valid-credential (credential-id uint))
    (match (map-get? Credentials credential-id)
        credential 
        (let
            (
                (is-expired (unwrap-panic (contract-call? .credential-operations is-credential-expired credential-id)))
            )
            (ok (and 
                (not (get revoked credential))
                (not is-expired)
            ))
        )
        (err err-invalid-credential)
    )
)

;; Helper for other contracts to access
(define-read-only (get-credential-counter)
    (ok (var-get credential-counter))
)

;; Increment the credential counter - restricted to credential operations contract
(define-public (increment-credential-counter)
    (begin
        (asserts! (is-contract-call .credential-operations) err-not-authorized)
        (var-set credential-counter (+ (var-get credential-counter) u1))
        (ok (var-get credential-counter))
    )
)

;; Helper to check caller
(define-private (is-contract-call (contract principal))
    (is-eq contract-caller contract)
)

;; Set credential
(define-public (set-credential 
    (credential-id uint)
    (credential-data {
        recipient: principal,
        issuer: principal,
        credential-type: (string-utf8 256),
        issue-date: uint,
        expiry-date: (optional uint),
        metadata-hash: (string-ascii 64),
        revoked: bool,
        version: uint
    }))
    (begin
        (asserts! (is-contract-call .credential-operations) err-not-authorized)
        (map-set Credentials credential-id credential-data)
        (ok true)
    )
)

;; Initialize contract
(begin
    (var-set credential-counter u0)
)