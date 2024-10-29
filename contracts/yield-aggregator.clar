;; Title: Yield Aggregator Protocol
;; Description: A yield optimization protocol that automatically allocates funds across different yield farming opportunities

;; Constants and Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-STRATEGY-EXISTS (err u103))
(define-constant ERR-STRATEGY-NOT-FOUND (err u104))
(define-constant ERR-STRATEGY-DISABLED (err u105))
(define-constant ERR-MAX-STRATEGIES-REACHED (err u106))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u107))
(define-constant ERR-EMERGENCY-SHUTDOWN (err u108))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var emergency-shutdown bool false)
(define-data-var total-value-locked uint u0)
(define-data-var performance-fee uint u200) ;; 2% represented as basis points
(define-data-var management-fee uint u100)  ;; 1% represented as basis points
(define-data-var max-strategies uint u10)