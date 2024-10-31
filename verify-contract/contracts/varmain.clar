;; Digital Credential Verification System
;; Implementation in Clarity for Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-credential (err u103))
(define-constant err-revoked (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-expired (err u106))
(define-constant err-self-transfer (err u107))
(define-constant err-future-date (err u108))
(define-constant max-string-length u256)

;; Data Variables
(define-data-var credential-counter uint u0)

;; Data Maps
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

(define-map Issuers
    principal
    {
        active: bool,
        name: (string-utf8 64),
        added-at: uint,
        credential-count: uint
    }
)

;; New map for recipient credentials
(define-map RecipientCredentials
    { recipient: principal, credential-type: (string-utf8 256) }
    (list 100 uint)
)

;; Events
(define-data-var last-event-id uint u0)

(define-map Events
    uint
    {
        event-type: (string-utf8 32),
        credential-id: (optional uint),
        principal: principal,
        timestamp: uint
    }
)

;; Private Functions
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner)
)

(define-private (is-authorized-issuer (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (get active issuer-data)
        false
    )
)

(define-private (is-valid-future-date (date uint))
    (< block-height date)
)

(define-private (is-credential-expired (credential-id uint))
    (match (map-get? Credentials credential-id)
        credential (match (get expiry-date credential)
            expiry (>= block-height expiry)
            false
        )
        true
    )
)

(define-private (increment-issuer-credential-count (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (map-set Issuers 
            issuer
            (merge issuer-data { credential-count: (+ (get credential-count issuer-data) u1) })
        )
        false
    )
)

(define-private (emit-event (event-type (string-utf8 32)) (credential-id (optional uint)))
    (let
        (
            (new-id (+ (var-get last-event-id) u1))
        )
        (map-set Events new-id
            {
                event-type: event-type,
                credential-id: credential-id,
                principal: tx-sender,
                timestamp: block-height
            }
        )
        (var-set last-event-id new-id)
        (ok new-id)
    )
)

;; New helper function to add credential to recipient's list
(define-private (add-to-recipient-credentials (recipient principal) (credential-type (string-utf8 256)) (credential-id uint))
    (let
        (
            (key { recipient: recipient, credential-type: credential-type })
            (existing-list (default-to (list) (map-get? RecipientCredentials key)))
        )
        (map-set RecipientCredentials
            key
            (unwrap-panic (as-max-len? (append existing-list credential-id) u100))
        )
    )
)

;; Public Functions - Administrative
(define-public (add-issuer (issuer principal) (name (string-utf8 64)))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (asserts! (is-none (map-get? Issuers issuer)) err-already-exists)
        (map-set Issuers issuer
            {
                active: true,
                name: name,
                added-at: block-height,
                credential-count: u0
            }
        )
        (emit-event "issuer-added" none)
        (ok true)
    )
)

;; New function to update credential metadata
(define-public (update-credential-metadata 
    (credential-id uint)
    (new-metadata-hash (string-ascii 64)))
    (match (map-get? Credentials credential-id)
        credential (begin
            (asserts! (is-eq (get issuer credential) tx-sender) err-not-authorized)
            (asserts! (not (get revoked credential)) err-revoked)
            (map-set Credentials credential-id
                (merge credential { 
                    metadata-hash: new-metadata-hash,
                    version: (+ (get version credential) u1)
                })
            )
            (emit-event "credential-updated" (some credential-id))
            (ok true)
        )
        err-invalid-credential
    )
)

;; Enhanced issue-credential function with additional validation
(define-public (issue-credential
    (recipient principal)
    (credential-type (string-utf8 256))
    (expiry-date (optional uint))
    (metadata-hash (string-ascii 64)))
    (let
        (
            (credential-id (+ (var-get credential-counter) u1))
        )
        (asserts! (is-authorized-issuer tx-sender) err-not-authorized)
        (asserts! (>= (len credential-type) u1) err-invalid-params)
        (asserts! (<= (len credential-type) max-string-length) err-invalid-params)
        (match expiry-date
            expiry (asserts! (is-valid-future-date expiry) err-future-date)
            true
        )
        
        (map-set Credentials credential-id
            {
                recipient: recipient,
                issuer: tx-sender,
                credential-type: credential-type,
                issue-date: block-height,
                expiry-date: expiry-date,
                metadata-hash: metadata-hash,
                revoked: false,
                version: u1
            }
        )
        (var-set credential-counter credential-id)
        (increment-issuer-credential-count tx-sender)
        (add-to-recipient-credentials recipient credential-type credential-id)
        (emit-event "credential-issued" (some credential-id))
        (ok credential-id)
    )
)

;; Enhanced transfer with additional checks
(define-public (transfer-credential-ownership (credential-id uint) (new-owner principal))
    (match (map-get? Credentials credential-id)
        credential (begin
            (asserts! (is-eq (get recipient credential) tx-sender) err-not-authorized)
            (asserts! (not (get revoked credential)) err-revoked)
            (asserts! (not (is-credential-expired credential-id)) err-expired)
            (asserts! (not (is-eq new-owner tx-sender)) err-self-transfer)
            (map-set Credentials credential-id
                (merge credential { recipient: new-owner })
            )
            (add-to-recipient-credentials new-owner (get credential-type credential) credential-id)
            (emit-event "credential-transferred" (some credential-id))
            (ok true)
        )
        err-invalid-credential
    )
)

;; New read-only functions
(define-read-only (get-recipient-credentials (recipient principal) (credential-type (string-utf8 256)))
    (ok (default-to (list) (map-get? RecipientCredentials { recipient: recipient, credential-type: credential-type })))
)

(define-read-only (get-issuer-stats (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (ok {
            name: (get name issuer-data),
            active: (get active issuer-data),
            credential-count: (get credential-count issuer-data),
            added-at: (get added-at issuer-data)
        })
        err-invalid-params
    )
)

(define-read-only (is-valid-credential (credential-id uint))
    (match (map-get? Credentials credential-id)
        credential (ok (and 
            (not (get revoked credential))
            (not (is-credential-expired credential-id))
        ))
        err-invalid-credential
    )
)

;; Initialize contract
(begin
    (var-set credential-counter u0)
    (var-set last-event-id u0)
)
