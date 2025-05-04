;; Digital Credential Verification System - Utilities
;; Common utility functions used across modules

;; String validation
(define-read-only (is-valid-string (str (string-utf8 256)) (min-length uint) (max-length uint))
    (ok (and
        (>= (len str) min-length)
        (<= (len str) max-length)
        (not (is-eq str u""))
    ))
)

;; Date validation
(define-read-only (is-date-in-future (date uint))
    (ok (< block-height date))
)

