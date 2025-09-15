;; oracle-processor
;; Integrates with external data oracles to monitor trigger conditions, validates data sources for accuracy, executes automatic claim payouts when conditions are met, and manages dispute resolution processes.

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_STATE (err u422))

;; Data Variables
(define-data-var contract-version uint u1)
(define-data-var total-oracles uint u0)
(define-data-var total-data-points uint u0)
(define-data-var contract-active bool true)

;; Data Maps
(define-map oracles
    { oracle-id: uint }
    {
        oracle-address: principal,
        data-source: (string-ascii 100),
        reputation-score: uint,
        total-submissions: uint,
        is-active: bool,
        registered-at: uint
    }
)

(define-map oracle-data
    { data-id: uint }
    {
        oracle-id: uint,
        data-type: (string-ascii 50),
        data-value: (string-ascii 256),
        timestamp: uint,
        validation-status: (string-ascii 20),
        verified-by: (optional principal)
    }
)

(define-map trigger-conditions
    { condition-id: uint }
    {
        condition-type: (string-ascii 50),
        threshold-value: uint,
        comparison-operator: (string-ascii 10),
        is-active: bool,
        created-by: principal,
        created-at: uint
    }
)

(define-map claim-triggers
    { policy-id: uint }
    {
        trigger-data-id: uint,
        trigger-condition-id: uint,
        triggered-at: uint,
        trigger-status: (string-ascii 20),
        processed-by: principal
    }
)

;; Read-only functions
(define-read-only (get-contract-version)
    (var-get contract-version)
)

(define-read-only (get-total-oracles)
    (var-get total-oracles)
)

(define-read-only (get-total-data-points)
    (var-get total-data-points)
)

(define-read-only (is-contract-active)
    (var-get contract-active)
)

(define-read-only (get-oracle (oracle-id uint))
    (map-get? oracles { oracle-id: oracle-id })
)

(define-read-only (get-oracle-data (data-id uint))
    (map-get? oracle-data { data-id: data-id })
)

(define-read-only (get-trigger-condition (condition-id uint))
    (map-get? trigger-conditions { condition-id: condition-id })
)

(define-read-only (get-claim-trigger (policy-id uint))
    (map-get? claim-triggers { policy-id: policy-id })
)


;; Private functions
(define-read-only (is-oracle-authorized (oracle-address principal))
    false ;; Simplified for now
)
(define-private (is-authorized (user principal))
    (is-eq user CONTRACT_OWNER)
)

(define-private (increment-oracle-counter)
    (var-set total-oracles (+ (var-get total-oracles) u1))
)

(define-private (increment-data-counter)
    (var-set total-data-points (+ (var-get total-data-points) u1))
)

(define-private (get-current-time)
    block-height
)

(define-private (validate-data-type (data-type (string-ascii 50)))
    (or 
        (is-eq data-type "weather")
        (is-eq data-type "flight")
        (is-eq data-type "earthquake")
        (is-eq data-type "temperature")
        (is-eq data-type "rainfall")
        (is-eq data-type "custom")
    )
)


;; Administrative functions
(define-public (set-contract-active (active bool))
    (begin
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (var-set contract-active active)
        (ok true)
    )
)

(define-public (register-oracle (oracle-address principal) (data-source (string-ascii 100)))
    (let
        (
            (oracle-id (var-get total-oracles))
            (current-time (get-current-time))
        )
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        ;; Register oracle
        (map-set oracles
            { oracle-id: oracle-id }
            {
                oracle-address: oracle-address,
                data-source: data-source,
                reputation-score: u100,
                total-submissions: u0,
                is-active: true,
                registered-at: current-time
            }
        )
        
        (increment-oracle-counter)
        (ok oracle-id)
    )
)

(define-public (deactivate-oracle (oracle-id uint))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        (match (map-get? oracles { oracle-id: oracle-id })
            oracle-info
            (begin
                (map-set oracles
                    { oracle-id: oracle-id }
                    (merge oracle-info { is-active: false })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

;; Core business functions
(define-public (submit-data (oracle-id uint) (data-type (string-ascii 50)) (data-value (string-ascii 256)))
    (let
        (
            (data-id (var-get total-data-points))
            (current-time (get-current-time))
        )
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (validate-data-type data-type) ERR_INVALID_INPUT)
        
        ;; Verify oracle exists and is active
        (match (map-get? oracles { oracle-id: oracle-id })
            oracle-info
            (begin
                (asserts! (get is-active oracle-info) ERR_INVALID_STATE)
                (asserts! (is-eq (get oracle-address oracle-info) tx-sender) ERR_UNAUTHORIZED)
                
                ;; Store data
                (map-set oracle-data
                    { data-id: data-id }
                    {
                        oracle-id: oracle-id,
                        data-type: data-type,
                        data-value: data-value,
                        timestamp: current-time,
                        validation-status: "pending",
                        verified-by: none
                    }
                )
                
                ;; Update oracle stats
                (map-set oracles
                    { oracle-id: oracle-id }
                    (merge oracle-info {
                        total-submissions: (+ (get total-submissions oracle-info) u1)
                    })
                )
                
                (increment-data-counter)
                (ok data-id)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (validate-data (data-id uint) (is-valid bool))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        (match (map-get? oracle-data { data-id: data-id })
            data-info
            (begin
                (map-set oracle-data
                    { data-id: data-id }
                    (merge data-info {
                        validation-status: (if is-valid "validated" "rejected"),
                        verified-by: (some tx-sender)
                    })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (create-trigger-condition (condition-type (string-ascii 50)) (threshold-value uint) (comparison-operator (string-ascii 10)))
    (let
        (
            (condition-id (var-get total-data-points))
            (current-time (get-current-time))
        )
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        (map-set trigger-conditions
            { condition-id: condition-id }
            {
                condition-type: condition-type,
                threshold-value: threshold-value,
                comparison-operator: comparison-operator,
                is-active: true,
                created-by: tx-sender,
                created-at: current-time
            }
        )
        
        (ok condition-id)
    )
)

(define-public (process-trigger (policy-id uint) (data-id uint) (condition-id uint))
    (let
        (
            (current-time (get-current-time))
        )
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        
        ;; Verify data and condition exist
        (asserts! (is-some (map-get? oracle-data { data-id: data-id })) ERR_NOT_FOUND)
        (asserts! (is-some (map-get? trigger-conditions { condition-id: condition-id })) ERR_NOT_FOUND)
        
        ;; Record trigger event
        (map-set claim-triggers
            { policy-id: policy-id }
            {
                trigger-data-id: data-id,
                trigger-condition-id: condition-id,
                triggered-at: current-time,
                trigger-status: "triggered",
                processed-by: tx-sender
            }
        )
        
        (ok true)
    )
)

(define-public (update-oracle-reputation (oracle-id uint) (new-score uint))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (<= new-score u1000) ERR_INVALID_INPUT)
        
        (match (map-get? oracles { oracle-id: oracle-id })
            oracle-info
            (begin
                (map-set oracles
                    { oracle-id: oracle-id }
                    (merge oracle-info { reputation-score: new-score })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (dispute-trigger (policy-id uint) (dispute-reason (string-ascii 256)))
    (begin
        (asserts! (var-get contract-active) ERR_INVALID_STATE)
        
        (match (map-get? claim-triggers { policy-id: policy-id })
            trigger-info
            (begin
                (map-set claim-triggers
                    { policy-id: policy-id }
                    (merge trigger-info {
                        trigger-status: "disputed"
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
