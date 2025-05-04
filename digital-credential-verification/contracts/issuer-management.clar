;; Digital Credential Verification System - Issuer Management
;; Handles issuer registration, removal, and status updates

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-params (err u105))
(define-constant err-invalid-name (err u110))

;; Event Types
(define-constant EVENT-ISSUER-ADDED u"issuer-added")
(define-constant EVENT-ISSUER-REMOVED u"issuer-removed")
(define-constant EVENT-ISSUER-UPDATED u"issuer-updated")

;; Define trait for other contracts to interact with this contract
(define-trait issuer-trait
    (
        (is-authorized-issuer (principal) (response bool uint))
        (increment-issuer-credential-count (principal) (response bool uint))
    )
)

;; Data Maps
(define-map Issuers
    principal
    {
        active: bool,
        name: (string-utf8 64),
        added-at: uint,
        credential-count: uint
    }
)

;; Private Functions
(define-private (is-valid-name (name (string-utf8 64)))
    (unwrap-panic (contract-call? .utilities is-valid-string name u1 u64))
)

;; Helper to check caller
(define-private (is-contract-call (contract principal))
    (is-eq contract-caller contract)
)

;; Public Functions
(define-public (add-issuer (issuer principal) (name (string-utf8 64)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? Issuers issuer)) err-already-exists)
        (asserts! (is-valid-name name) err-invalid-name)
        (asserts! (map-set Issuers issuer
            {
                active: true,
                name: name,
                added-at: block-height,
                credential-count: u0
            }
        ) err-invalid-params)
        (try! (contract-call? .event-module emit-event EVENT-ISSUER-ADDED none tx-sender))
        (ok true)
    )
)

(define-public (remove-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? Issuers issuer)) err-invalid-params)
        (map-delete Issuers issuer)
        (try! (contract-call? .event-module emit-event EVENT-ISSUER-REMOVED none tx-sender))
        (ok true)
    )
)

(define-public (update-issuer-status (issuer principal) (active bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? Issuers issuer)
            issuer-data (begin
                (asserts! (map-set Issuers issuer
                    (merge issuer-data { active: active })
                ) err-invalid-params)
                (try! (contract-call? .event-module emit-event EVENT-ISSUER-UPDATED none tx-sender))
                (ok true)
            )
            (err err-invalid-params)
        )
    )
)

;; Read-only Functions
(define-read-only (is-authorized-issuer (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (ok (get active issuer-data))
        (ok false)
    )
)

(define-read-only (get-issuer-status (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (ok (get active issuer-data))
        (ok false)
    )
)

(define-read-only (get-issuer-stats (issuer principal))
    (match (map-get? Issuers issuer)
        issuer-data (ok {
            name: (get name issuer-data),
            active: (get active issuer-data),
            credential-count: (get credential-count issuer-data),
            added-at: (get added-at issuer-data)
        })
        (err err-invalid-params)
    )
)

(define-public (increment-issuer-credential-count (issuer principal))
    (begin
        (asserts! (is-contract-call .credential-operations) err-not-authorized)
        (match (map-get? Issuers issuer)
            issuer-data (begin
                (map-set Issuers 
                    issuer
                    (merge issuer-data { credential-count: (+ (get credential-count issuer-data) u1) })
                )
                (ok true)
            )
            (err err-invalid-params)
        )
    )
)