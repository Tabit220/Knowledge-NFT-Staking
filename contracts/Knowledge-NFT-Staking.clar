;; title: Knowledge-NFT-Staking

(define-trait nft-trait
  ((get-last-token-id () (response uint uint))
   (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
   (get-owner (uint) (response (optional principal) uint))
   (transfer (uint principal principal) (response bool uint))))

(define-fungible-token knowledge-token)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_STAKED (err u102))
(define-constant ERR_NOT_STAKED (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant MIN_STAKE_PERIOD u144)
(define-constant TIER_1_BLOCKS u1008)
(define-constant TIER_2_BLOCKS u4320)
(define-constant TIER_3_BLOCKS u12960)
(define-constant MULTIPLIER_BASE u100)
(define-constant MULTIPLIER_TIER_1 u150)
(define-constant MULTIPLIER_TIER_2 u200)
(define-constant MULTIPLIER_TIER_3 u300)

(define-data-var next-module-id uint u1)
(define-data-var total-rewards-pool uint u0)

(define-map modules 
  { module-id: uint }
  { 
    educator: principal,
    title: (string-ascii 256),
    description: (string-ascii 512),
    reward-per-use: uint,
    total-uses: uint,
    is-active: bool
  })

(define-map staked-nfts
  { nft-contract: principal, token-id: uint }
  {
    staker: principal,
    module-id: uint,
    stake-block: uint,
    reward-earned: uint
  })

(define-map user-stakes
  { user: principal }
  { 
    total-staked: uint,
    total-rewards: uint
  })

(define-map educator-stats
  { educator: principal }
  {
    modules-created: uint,
    total-earnings: uint
  })

(define-map module-usage
  { module-id: uint, school: principal }
  {
    uses: uint,
    last-used: uint
  })

(define-public (create-module (title (string-ascii 256)) (description (string-ascii 512)) (reward-per-use uint))
  (let ((module-id (var-get next-module-id)))
    (begin
      (asserts! (> reward-per-use u0) ERR_INVALID_AMOUNT)
      (map-set modules 
        { module-id: module-id }
        {
          educator: tx-sender,
          title: title,
          description: description,
          reward-per-use: reward-per-use,
          total-uses: u0,
          is-active: true
        })
      (map-set educator-stats
        { educator: tx-sender }
        (merge 
          (default-to { modules-created: u0, total-earnings: u0 } 
                     (map-get? educator-stats { educator: tx-sender }))
          { modules-created: (+ (get modules-created 
                                    (default-to { modules-created: u0, total-earnings: u0 } 
                                               (map-get? educator-stats { educator: tx-sender }))) u1) }))
      (var-set next-module-id (+ module-id u1))
      (ok module-id))))

(define-public (stake-nft (nft-contract <nft-trait>) (token-id uint) (module-id uint))
  (let ((nft-owner (unwrap! (contract-call? nft-contract get-owner token-id) ERR_NOT_FOUND))
        (module-data (unwrap! (map-get? modules { module-id: module-id }) ERR_NOT_FOUND)))
    (begin
      (asserts! (is-eq (some tx-sender) nft-owner) ERR_UNAUTHORIZED)
      (asserts! (get is-active module-data) ERR_NOT_FOUND)
      (asserts! (is-none (map-get? staked-nfts { nft-contract: (contract-of nft-contract), token-id: token-id })) ERR_ALREADY_STAKED)
      (map-set staked-nfts
        { nft-contract: (contract-of nft-contract), token-id: token-id }
        {
          staker: tx-sender,
          module-id: module-id,
          stake-block: stacks-block-height,
          reward-earned: u0
        })
      (map-set user-stakes
        { user: tx-sender }
        (merge
          (default-to { total-staked: u0, total-rewards: u0 } 
                     (map-get? user-stakes { user: tx-sender }))
          { total-staked: (+ (get total-staked 
                                 (default-to { total-staked: u0, total-rewards: u0 } 
                                            (map-get? user-stakes { user: tx-sender }))) u1) }))
      (ok true))))

(define-public (unstake-nft (nft-contract principal) (token-id uint))
  (let ((stake-data (unwrap! (map-get? staked-nfts { nft-contract: nft-contract, token-id: token-id }) ERR_NOT_STAKED))
        (stake-duration (- stacks-block-height (get stake-block stake-data)))
        (multiplier (calculate-multiplier stake-duration))
        (base-reward (get reward-earned stake-data))
        (boosted-reward (apply-multiplier base-reward multiplier)))
    (begin
      (asserts! (is-eq (get staker stake-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (>= stacks-block-height (+ (get stake-block stake-data) MIN_STAKE_PERIOD)) ERR_UNAUTHORIZED)
      (if (> boosted-reward u0)
        (try! (ft-mint? knowledge-token boosted-reward tx-sender))
        false)
      (map-delete staked-nfts { nft-contract: nft-contract, token-id: token-id })
      (map-set user-stakes
        { user: tx-sender }
        (merge
          (default-to { total-staked: u0, total-rewards: u0 } 
                     (map-get? user-stakes { user: tx-sender }))
          { 
            total-staked: (- (get total-staked 
                                 (default-to { total-staked: u0, total-rewards: u0 } 
                                            (map-get? user-stakes { user: tx-sender }))) u1),
            total-rewards: (+ (get total-rewards 
                                  (default-to { total-staked: u0, total-rewards: u0 } 
                                             (map-get? user-stakes { user: tx-sender }))) 
                             boosted-reward)
          }))
      (ok true))))

(define-public (use-module (module-id uint) (school principal))
  (let ((module-data (unwrap! (map-get? modules { module-id: module-id }) ERR_NOT_FOUND))
        (usage-data (default-to { uses: u0, last-used: u0 } 
                                (map-get? module-usage { module-id: module-id, school: school }))))
    (begin
      (asserts! (get is-active module-data) ERR_NOT_FOUND)
      (map-set modules 
        { module-id: module-id }
        (merge module-data { total-uses: (+ (get total-uses module-data) u1) }))
      (map-set module-usage
        { module-id: module-id, school: school }
        {
          uses: (+ (get uses usage-data) u1),
          last-used: stacks-block-height
        })
      (try! (ft-mint? knowledge-token (get reward-per-use module-data) (get educator module-data)))
      (map-set educator-stats
        { educator: (get educator module-data) }
        (merge 
          (default-to { modules-created: u0, total-earnings: u0 } 
                     (map-get? educator-stats { educator: (get educator module-data) }))
          { total-earnings: (+ (get total-earnings 
                                   (default-to { modules-created: u0, total-earnings: u0 } 
                                              (map-get? educator-stats { educator: (get educator module-data) }))) 
                              (get reward-per-use module-data)) }))
      (try! (distribute-staker-rewards module-id))
      (ok true))))

(define-public (deactivate-module (module-id uint))
  (let ((module-data (unwrap! (map-get? modules { module-id: module-id }) ERR_NOT_FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get educator module-data)) ERR_UNAUTHORIZED)
      (map-set modules 
        { module-id: module-id }
        (merge module-data { is-active: false }))
      (ok true))))

(define-public (add-rewards-to-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (try! (ft-mint? knowledge-token amount tx-sender))
    (var-set total-rewards-pool (+ (var-get total-rewards-pool) amount))
    (ok true)))

(define-private (calculate-multiplier (stake-duration uint))
  (if (>= stake-duration TIER_3_BLOCKS)
    MULTIPLIER_TIER_3
    (if (>= stake-duration TIER_2_BLOCKS)
      MULTIPLIER_TIER_2
      (if (>= stake-duration TIER_1_BLOCKS)
        MULTIPLIER_TIER_1
        MULTIPLIER_BASE))))

(define-private (apply-multiplier (base-reward uint) (multiplier uint))
  (/ (* base-reward multiplier) MULTIPLIER_BASE))

(define-private (distribute-staker-rewards (module-id uint))
  (let ((reward-per-staker u10))
    (begin
      (try! (ft-mint? knowledge-token reward-per-staker tx-sender))
      (ok true))))

(define-read-only (get-module-info (module-id uint))
  (map-get? modules { module-id: module-id }))

(define-read-only (get-stake-info (nft-contract principal) (token-id uint))
  (map-get? staked-nfts { nft-contract: nft-contract, token-id: token-id }))

(define-read-only (get-user-stats (user principal))
  (default-to { total-staked: u0, total-rewards: u0 } 
             (map-get? user-stakes { user: user })))

(define-read-only (get-educator-stats (educator principal))
  (default-to { modules-created: u0, total-earnings: u0 } 
             (map-get? educator-stats { educator: educator })))

(define-read-only (get-module-usage (module-id uint) (school principal))
  (default-to { uses: u0, last-used: u0 } 
             (map-get? module-usage { module-id: module-id, school: school })))

(define-read-only (get-next-module-id)
  (var-get next-module-id))

(define-read-only (get-total-rewards-pool)
  (var-get total-rewards-pool))

(define-read-only (get-token-balance (user principal))
  (ft-get-balance knowledge-token user))

(define-read-only (get-stake-multiplier (nft-contract principal) (token-id uint))
  (match (map-get? staked-nfts { nft-contract: nft-contract, token-id: token-id })
    stake-data
      (let ((stake-duration (- stacks-block-height (get stake-block stake-data))))
        (ok (calculate-multiplier stake-duration)))
    ERR_NOT_STAKED))

(define-read-only (get-boosted-rewards (nft-contract principal) (token-id uint))
  (match (map-get? staked-nfts { nft-contract: nft-contract, token-id: token-id })
    stake-data
      (let ((stake-duration (- stacks-block-height (get stake-block stake-data)))
            (multiplier (calculate-multiplier stake-duration))
            (base-reward (get reward-earned stake-data)))
        (ok (apply-multiplier base-reward multiplier)))
    ERR_NOT_STAKED))
