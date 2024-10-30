;; Title: Yield Aggregator Protocol
;; Description: A yield optimization protocol that automatically allocates funds across different yield farming opportunities

;; Define contract name
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; Constants and Error Codes
(define-constant contract-name "yield-aggregator")
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-STRATEGY-EXISTS (err u103))
(define-constant ERR-STRATEGY-NOT-FOUND (err u104))
(define-constant ERR-STRATEGY-DISABLED (err u105))
(define-constant ERR-MAX-STRATEGIES-REACHED (err u106))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u107))
(define-constant ERR-EMERGENCY-SHUTDOWN (err u108))
(define-constant ERR-TOKEN-NOT-SET (err u109))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var emergency-shutdown bool false)
(define-data-var total-value-locked uint u0)
(define-data-var performance-fee uint u200) ;; 2% represented as basis points
(define-data-var management-fee uint u100)  ;; 1% represented as basis points
(define-data-var max-strategies uint u10)
(define-data-var token-contract (optional principal) none)

;; Data Maps
(define-map Strategies
    { strategy-id: uint }
    {
        name: (string-utf8 64),
        protocol: (string-utf8 64),
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint,
        last-harvest: uint
    }
)

(define-map UserDeposits
    { user: principal }
    {
        total-deposit: uint,
        share-tokens: uint,
        last-deposit-block: uint
    }
)

(define-map StrategyAllocations
    { strategy-id: uint }
    {
        allocation-percentage: uint,
        min-deposit: uint,
        max-deposit: uint
    }
)

;; Read-only Functions
(define-read-only (get-strategy-list)
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)
)

(define-read-only (get-strategy-info (strategy-id uint))
    (map-get? Strategies { strategy-id: strategy-id })
)

(define-read-only (get-user-info (user principal))
    (map-get? UserDeposits { user: user })
)

(define-read-only (get-total-tvl)
    (var-get total-value-locked)
)

(define-read-only (get-token-contract)
    (var-get token-contract)
)

(define-read-only (calculate-best-strategy (amount uint))
    (let
        (
            (strategies (get-active-strategies))
            (best-apy u0)
            (best-strategy u0)
        )
        (unwrap! (element-at strategies u0) (tuple (best-apy u0) (best-strategy u0)))
    )
)

(define-read-only (get-active-strategies)
    (let
        ((strategy-1 (unwrap-strategy u1))
         (strategy-2 (unwrap-strategy u2)))
        (filter is-strategy-active (list strategy-1 strategy-2))
    )
)

;; Private Functions
(define-private (is-strategy-active (strategy {
        strategy-id: uint,
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint
    }))
    (and (get enabled strategy) (> (get apy strategy) u0))
)

(define-private (calculate-highest-apy (strategy {
        strategy-id: uint,
        enabled: bool,
        tvl: uint,
        apy: uint,
        risk-score: uint
    }) (acc {best-apy: uint, best-strategy: uint}))
    (if (and
            (get enabled strategy)
            (> (get apy strategy) (get best-apy acc))
        )
        (tuple 
            (best-apy (get apy strategy))
            (best-strategy (get strategy-id strategy))
        )
        acc
    )
)

;; Public Functions
(define-public (deposit (amount uint))
    (let
        (
            (user tx-sender)
            (current-deposit (default-to { total-deposit: u0, share-tokens: u0, last-deposit-block: u0 }
                (map-get? UserDeposits { user: user })))
            (token (unwrap! (var-get token-contract) ERR-TOKEN-NOT-SET))
        )
        (asserts! (not (var-get emergency-shutdown)) ERR-EMERGENCY-SHUTDOWN)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer tokens to contract
        (try! (contract-call? token transfer
            amount
            tx-sender
            (as-contract tx-sender)
            none))
        
        (let
            (
                (new-shares (calculate-shares amount))
                (new-total-deposit (+ (get total-deposit current-deposit) amount))
            )
            (map-set UserDeposits
                { user: user }
                {
                    total-deposit: new-total-deposit,
                    share-tokens: (+ (get share-tokens current-deposit) new-shares),
                    last-deposit-block: block-height
                }
            )
            
            (var-set total-value-locked (+ (var-get total-value-locked) amount))
            
            (try! (allocate-to-best-strategy amount))
            
            (ok true)
        )
    )
)

(define-public (withdraw (share-amount uint))
    (let
        (
            (user tx-sender)
            (user-deposit (unwrap! (map-get? UserDeposits { user: user }) ERR-INSUFFICIENT-BALANCE))
            (token (unwrap! (var-get token-contract) ERR-TOKEN-NOT-SET))
        )
        (asserts! (<= share-amount (get share-tokens user-deposit)) ERR-INSUFFICIENT-BALANCE)
        
        (let
            (
                (withdrawal-amount (calculate-withdrawal-amount share-amount))
                (new-shares (- (get share-tokens user-deposit) share-amount))
            )
            (map-set UserDeposits
                { user: user }
                {
                    total-deposit: (- (get total-deposit user-deposit) withdrawal-amount),
                    share-tokens: new-shares,
                    last-deposit-block: (get last-deposit-block user-deposit)
                }
            )
            
            (var-set total-value-locked (- (var-get total-value-locked) withdrawal-amount))
            
            ;; Transfer tokens back to user
            (try! (as-contract (contract-call? token transfer
                withdrawal-amount
                tx-sender
                user
                none)))
            
            (ok withdrawal-amount)
        )
    )
)

;; Admin Functions
(define-public (add-strategy (name (string-utf8 64)) (protocol (string-utf8 64)) (min-deposit uint) (max-deposit uint))
    (let
        (
            (strategy-count (len (get-strategy-list)))
        )
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (< strategy-count (var-get max-strategies)) ERR-MAX-STRATEGIES-REACHED)
        
        (map-set Strategies
            { strategy-id: (+ strategy-count u1) }
            {
                name: name,
                protocol: protocol,
                enabled: true,
                tvl: u0,
                apy: u0,
                risk-score: u0,
                last-harvest: block-height
            }
        )
        
        (map-set StrategyAllocations
            { strategy-id: (+ strategy-count u1) }
            {
                allocation-percentage: u0,
                min-deposit: min-deposit,
                max-deposit: max-deposit
            }
        )
        
        (ok true)
    )
)

(define-public (update-strategy-apy (strategy-id uint) (new-apy uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (map-get? Strategies { strategy-id: strategy-id }) ERR-STRATEGY-NOT-FOUND)
        
        (map-set Strategies
            { strategy-id: strategy-id }
            (merge (unwrap! (map-get? Strategies { strategy-id: strategy-id }) ERR-STRATEGY-NOT-FOUND)
                  { apy: new-apy })
        )
        (ok true)
    )
)

(define-public (toggle-emergency-shutdown)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set emergency-shutdown (not (var-get emergency-shutdown)))
        (ok true)
    )
)

(define-public (set-token-contract (new-token principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set token-contract (some new-token))
        (ok true)
    )
)

;; Helper Functions
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

(define-private (calculate-shares (amount uint))
    (let
        (
            (total-supply (var-get total-value-locked))
        )
        (if (is-eq total-supply u0)
            amount
            (/ (* amount u1000000) total-supply)
        )
    )
)

(define-private (calculate-withdrawal-amount (share-amount uint))
    (let
        (
            (total-shares (var-get total-value-locked))
        )
        (/ (* share-amount (var-get total-value-locked)) u1000000)
    )
)

(define-private (allocate-to-best-strategy (amount uint))
    (let
        (
            (best-strategy (calculate-best-strategy amount))
        )
        (if (is-eq (get best-strategy best-strategy) u0)
            (ok true)
            (try! (reallocate-funds (get best-strategy best-strategy) amount))
        )
        (ok true)
    )
)

(define-private (reallocate-funds (strategy-id uint) (amount uint))
    (let
        (
            (strategy (unwrap! (map-get? Strategies { strategy-id: strategy-id }) ERR-STRATEGY-NOT-FOUND))
            (allocation (unwrap! (map-get? StrategyAllocations { strategy-id: strategy-id }) ERR-STRATEGY-NOT-FOUND))
        )
        (asserts! (get enabled strategy) ERR-STRATEGY-DISABLED)
        (asserts! (>= amount (get min-deposit allocation)) ERR-INVALID-AMOUNT)
        (asserts! (<= amount (get max-deposit allocation)) ERR-INVALID-AMOUNT)
        
        ;; Update strategy TVL
        (map-set Strategies
            { strategy-id: strategy-id }
            (merge strategy { tvl: (+ (get tvl strategy) amount) })
        )
        
        (ok true)
    )
)

;; Convert strategy ID to full strategy info
(define-private (unwrap-strategy (strategy-id uint))
    (let
        (
            (strategy (map-get? Strategies { strategy-id: strategy-id }))
        )
        (if (is-some strategy)
            (let
                (
                    (name (get name (unwrap! strategy)))
                    (protocol (get protocol (unwrap! strategy)))
                )
                {
                    strategy-id: strategy-id,
                    name: name,
                    protocol: protocol,
                    enabled: (get enabled (unwrap! strategy)),
                    tvl: (get tvl (unwrap! strategy)),
                    apy: (get apy (unwrap! strategy)),
                    risk-score: (get risk-score (unwrap! strategy)),
                    last-harvest: (get last-harvest (unwrap! strategy))
                }
            )
            {
                strategy-id: strategy-id,
                name: (as-max-len? "default-name" 64),
                protocol: (as-max-len? "default-protocol" 64),
                enabled: false,
                tvl: u0,
                apy: u0,
                risk-score: u0,
                last-harvest: u0
            }
        )
    )
)