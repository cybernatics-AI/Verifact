;; Digital Credential Verification System - Credential Operations
;; Handles credential issuance, revocation, transfer, and updates

;; Constants
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-credential (err u103))
(define-constant err-revoked (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-expired (err u106))
(define-constant err-self-transfer (err u107))
(define-constant err-future-date (err u108))
(define-constant err-invalid-metadata (err u111))
(define-constant max-string-length u256)

;; Event Types
(define-constant EVENT-CREDENTIAL-ISSUED u"credential-issued")
(define-constant EVENT-CREDENTIAL-REVOKED u"credential-revoked")
(define-constant EVENT-CREDENTIAL-UPDATED u"credential-updated")
(define-constant EVENT-CREDENTIAL-TRANSFERRED u"credential-transfer")

;; Define trait for other contracts to interact with this contract
(define-trait credential-trait
    (
        (issue-credential (principal (string-utf8 256) (optional uint) (string-ascii 64)) (response uint uint))
        (revoke-credential (uint) (response bool uint))
        (transfer-credential-ownership (uint principal) (response bool uint))
        (update-credential-metadata (uint (string-ascii 64)) (response bool uint))
        (is-credential-expired (uint) (response bool uint))
    )
)

;; Map for recipient credentials
(define-map RecipientCredentials
    { recipient: principal, credential-type: (string-utf8 256) }
    (list 100 uint)
)

;; Private Functions
(define-private (is-valid-future-date (date uint))
    (unwrap-panic (contract-call? .utilities is-date-in-future date))
)

(define-private (is-valid-metadata-hash (hash (string-ascii 64)))
    (and
        (is-eq (len hash) u64)
        (not (is-eq hash ""))
    )
)

(define-public (is-credential-expired (credential-id uint))
    (match (contract-call? .digital-credentials get-credential-by-id credential-id)
        credential (match (get expiry-date credential)
            expiry (ok (>= block-height expiry))
            (ok false)
        )
        error (err error)
    )
)

;; Private helper function to add credential to recipient's list
(define-private (add-to-recipient-credentials (recipient principal) (credential-type (string-utf8 256)) (credential-id uint))
    (let
        (
            (key { recipient: recipient, credential-type: credential-type })
            (existing-list (default-to (list) (map-get? RecipientCredentials key)))
        )
        (if (map-set RecipientCredentials
            key
            (unwrap-panic (as-max-len? (append existing-list credential-id) u100)))
            (ok true)
            (err err-invalid-params)
        )
    )
)

;; Public Functions
(define-public (issue-credential
    (recipient principal)
    (credential-type (string-utf8 256))
    (expiry-date (optional uint))
    (metadata-hash (string-ascii 64)))
    (let
        (
            (auth-result (contract-call? .issuer-management is-authorized-issuer tx-sender))
        )
        (asserts! (unwrap! auth-result (err err-not-authorized)) err-not-authorized)
        (asserts! (>= (len credential-type) u1) err-invalid-params)
        (asserts! (<= (len credential-type) max-string-length) err-invalid-params)
        (asserts! (is-valid-metadata-hash metadata-hash) err-invalid-metadata)
        
        ;; Validate expiry date if provided
        (match expiry-date
            expiry (asserts! (is-valid-future-date expiry) err-future-date)
            true
        )
        
        (let 
            (
                (new-id-result (contract-call? .digital-credentials increment-credential-counter))
                (credential-id (unwrap! new-id-result (err err-invalid-params)))
            )
            (try! (contract-call? .digital-credentials set-credential 
                credential-id
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
            ))
            (try! (contract-call? .issuer-management increment-issuer-credential-count tx-sender))
            (try! (add-to-recipient-credentials recipient credential-type credential-id))
            (try! (contract-call? .event-module emit-event EVENT-CREDENTIAL-ISSUED (some credential-id) tx-sender))
            (ok credential-id)
        )
    )
)

(define-public (revoke-credential (credential-id uint))
    (match (contract-call? .digital-credentials get-credential-by-id credential-id)
        credential (begin
            (asserts! (is-eq (get issuer credential) tx-sender) err-not-authorized)
            (asserts! (not (get revoked credential)) err-revoked)
            (try! (contract-call? .digital-credentials set-credential 
                credential-id
                (merge credential { revoked: true })
            ))
            (try! (contract-call? .event-module emit-event EVENT-CREDENTIAL-REVOKED (some credential-id) tx-sender))
            (ok true)
        )
        error (err error)
    )
)

(define-public (transfer-credential-ownership (credential-id uint) (new-owner principal))
    (match (contract-call? .digital-credentials get-credential-by-id credential-id)
        credential (begin
            (asserts! (is-eq (get recipient credential) tx-sender) err-not-authorized)
            (asserts! (not (get revoked credential)) err-revoked)
            (asserts! (not (unwrap-panic (is-credential-expired credential-id))) err-expired)
            (asserts! (not (is-eq new-owner tx-sender)) err-self-transfer)
            (try! (contract-call? .digital-credentials set-credential 
                credential-id
                (merge credential { recipient: new-owner })
            ))
            (try! (add-to-recipient-credentials new-owner (get credential-type credential) credential-id))
            (try! (contract-call? .event-module emit-event EVENT-CREDENTIAL-TRANSFERRED (some credential-id) tx-sender))
            (ok true)
        )
        error (err error)
    )
)

(define-public (update-credential-metadata 
    (credential-id uint)
    (new-metadata-hash (string-ascii 64)))
    (begin
        (asserts! (is-valid-metadata-hash new-metadata-hash) err-invalid-metadata)
        (match (contract-call? .digital-credentials get-credential-by-id credential-id)
            credential (begin
                (asserts! (is-eq (get issuer credential) tx-sender) err-not-authorized)
                (asserts! (not (get revoked credential)) err-revoked)
                (try! (contract-call? .digital-credentials set-credential 
                    credential-id
                    (merge credential { 
                        metadata-hash: new-metadata-hash,
                        version: (+ (get version credential) u1)
                    })
                ))
                (try! (contract-call? .event-module emit-event EVENT-CREDENTIAL-UPDATED (some credential-id) tx-sender))
                (ok true)
            )
            error (err error)
        )
    )
)

(define-read-only (get-recipient-credentials (recipient principal) (credential-type (string-utf8 256)))
    (ok (default-to (list) (map-get? RecipientCredentials { recipient: recipient, credential-type: credential-type })))
)