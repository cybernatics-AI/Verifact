;; Digital Credential Verification System - Event Module
;; Handles event logging and tracking

;; Constants
(define-constant err-event-error (err u109))

;; Define trait for other contracts to interact with this contract
(define-trait event-trait
    (
        (emit-event ((string-utf8 32) (optional uint) principal) (response bool uint))
    )
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

;; Public functions
(define-public (emit-event (event-type (string-utf8 32)) (credential-id (optional uint)) (caller principal))
    (let
        (
            (new-id (+ (var-get last-event-id) u1))
        )
        (var-set last-event-id new-id)
        (if (map-set Events new-id
            {
                event-type: event-type,
                credential-id: credential-id,
                principal: caller,
                timestamp: block-height
            })
            (ok true)
            (err err-event-error)
        )
    )
)

;; Read-only functions
(define-read-only (get-last-event-id)
    (var-get last-event-id)
)

(define-read-only (get-event (event-id uint))
    (match (map-get? Events event-id)
        event (ok event)
        (err err-event-error)
    )
)

;; Initialize contract
(begin
    (var-set last-event-id u0)
)