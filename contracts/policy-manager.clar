;; policy-manager
;; Creates and manages parametric insurance policies, processes premium payments, defines trigger conditions for automatic payouts, and maintains policyholder records and coverage details.

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_EXPIRED (err u410))
(define-constant ERR_INVALID_STATE (err u422))

;; Data Variables
(define-data-var contract-version uint u1)
(define-data-var total-policies uint u0)
(define-data-var contract-active bool true)

;; Data Maps
(define-map policies
    { policy-id: uint }
    {
        policyholder: principal,
        policy-type: (string-ascii 50),
        premium-amount: uint,
        coverage-amount: uint,
        status: (string-ascii 20),
        created-at: uint,
        updated-at: uint
    }
)

(define-map user-policies
    { user: principal }
    { policy-count: uint, total-premiums-paid: uint }
)

;; Read-only functions
(define-read-only (get-contract-version)
    (var-get contract-version)
)

(define-read-only (get-total-policies)
    (var-get total-policies)
)

(define-read-only (is-contract-active)
    (var-get contract-active)
)

(define-read-only (get-policy (policy-id uint))
    (map-get? policies { policy-id: policy-id })
)

(define-read-only (get-user-policy-summary (user principal))
    (map-get? user-policies { user: user })
)

;; Private functions
(define-private (is-authorized (user principal))
    (is-eq user CONTRACT_OWNER)
)

(define-private (increment-policy-counter)
    (var-set total-policies (+ (var-get total-policies) u1))
)

(define-private (validate-coverage-amount (amount uint))
    (and (> amount u0) (<= amount u10000000000000))
)

(define-private (get-current-time)
    block-height
)

;; Administrative functions
(define-public (set-contract-active (active bool))
    (begin
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (var-set contract-active active)
        (ok true)
    )
)

;; Core business functions
(define-public (create-policy (policy-type (string-ascii 50)) (premium-amount uint) (coverage-amount uint))
    (let
        (
            (policy-id (var-get total-policies))
            (current-time (get-current-time))
        )
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (> premium-amount u0) ERR_INVALID_INPUT)
        (asserts! (validate-coverage-amount coverage-amount) ERR_INVALID_INPUT)
        
        ;; Create policy record
        (map-set policies
            { policy-id: policy-id }
            {
                policyholder: tx-sender,
                policy-type: policy-type,
                premium-amount: premium-amount,
                coverage-amount: coverage-amount,
                status: "active",
                created-at: current-time,
                updated-at: current-time
            }
        )
        
        ;; Update user policy summary
        (match (map-get? user-policies { user: tx-sender })
            existing-summary
            (map-set user-policies
                { user: tx-sender }
                {
                    policy-count: (+ (get policy-count existing-summary) u1),
                    total-premiums-paid: (+ (get total-premiums-paid existing-summary) premium-amount)
                }
            )
            (map-set user-policies
                { user: tx-sender }
                {
                    policy-count: u1,
                    total-premiums-paid: premium-amount
                }
            )
        )
        
        (increment-policy-counter)
        (ok policy-id)
    )
)

(define-public (update-policy-status (policy-id uint) (new-status (string-ascii 20)))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        (match (map-get? policies { policy-id: policy-id })
            policy-data
            (begin
                (map-set policies
                    { policy-id: policy-id }
                    (merge policy-data {
                        status: new-status,
                        updated-at: (get-current-time)
                    })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (cancel-policy (policy-id uint))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-some (map-get? policies { policy-id: policy-id })) ERR_NOT_FOUND)
        
        (match (map-get? policies { policy-id: policy-id })
            policy-data
            (begin
                (asserts! (is-eq (get policyholder policy-data) tx-sender) ERR_UNAUTHORIZED)
                
                (map-set policies
                    { policy-id: policy-id }
                    (merge policy-data {
                        status: "cancelled",
                        updated-at: (get-current-time)
                    })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

;; Emergency functions
(define-public (emergency-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-active false)
        (ok true)
    )
)

(define-public (emergency-unpause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-active true)
        (ok true)
    )
)
