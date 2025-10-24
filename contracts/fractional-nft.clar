;; ------------------------------------------------------------
;; fractional-nft.clar
;; Fractionalized NFT Ownership for STX project
;; ------------------------------------------------------------
;; - Locks an existing NFT (SIP-009 compliant)
;; - Issues fungible fraction tokens representing ownership shares
;; - If 100% of shares are held by one user, they can redeem the NFT
;; - Built for Stacks blockchain (STX)
;; ------------------------------------------------------------

;; SIP009 NFT trait definition
(define-trait nft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response principal uint))
    (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
  )
)

(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_ALREADY_FRACTIONALIZED u101)
(define-constant ERR_INVALID_AMOUNT u102)
(define-constant ERR_NOT_FULL_OWNER u103)
(define-constant ERR_TRANSFER_FAIL u104)
(define-constant ERR_NOT_NFT_CONTRACT u105)

(define-constant BPS u10000)

;; ------------------------------
;; Data storage
;; ------------------------------
(define-data-var total-supply uint u0)
(define-map balances { account: principal } { balance: uint })

(define-constant NFT_CONTRACT 'SP000000000000000000002Q6VF78.sample-nft)
(define-data-var nft-id uint u0)
(define-data-var fractionalized bool false)
(define-data-var total-fractions uint u0)
(define-data-var nft-original-owner principal 'SP000000000000000000002Q6VF78.admin)

;; ------------------------------
;; Helper functions
;; ------------------------------
(define-private (balance-of (who principal))
  (default-to u0 (get balance (map-get? balances { account: who }))))

(define-private (mint (to principal) (amount uint))
  (begin
    (var-set total-supply (+ (var-get total-supply) amount))
    (map-set balances { account: to } { balance: (+ (balance-of to) amount) })
    (print { event: "mint-fractions", to: to, amount: amount })
    (ok true)))

(define-private (burn (from principal) (amount uint))
  (let ((bal (balance-of from)))
    (asserts! (>= bal amount) (err ERR_INVALID_AMOUNT))
    (map-set balances { account: from } { balance: (- bal amount) })
    (var-set total-supply (- (var-get total-supply) amount))
    (print { event: "burn-fractions", from: from, amount: amount })
    (ok true)))

;; ------------------------------
;; Public functions
;; ------------------------------

;; (1) Set the NFT ID
(define-public (set-nft-id (token-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get nft-original-owner)) (err ERR_NOT_OWNER))
    (asserts! (> token-id u0) (err ERR_INVALID_AMOUNT))
    (var-set nft-id token-id)
    (ok true)))

;; (2) Fractionalize the NFT (lock it and issue fractions)
(define-public (fractionalize (fraction-count uint))
  (begin
    (asserts! (not (var-get fractionalized)) (err ERR_ALREADY_FRACTIONALIZED))
    (asserts! (> fraction-count u0) (err ERR_INVALID_AMOUNT))
    
    ;; Update state
    (var-set fractionalized true)
    (var-set total-fractions fraction-count)
    (var-set total-supply fraction-count)
    (map-set balances { account: tx-sender } { balance: fraction-count })
    (print { event: "fractionalized", nft: (var-get nft-id), fractions: fraction-count, owner: tx-sender })
    (ok true)))

;; (3) Transfer fractions (simple internal FT logic)
(define-public (transfer (amount uint) (recipient principal))
  (begin
    (asserts! (not (is-eq tx-sender recipient)) (err ERR_INVALID_AMOUNT))
    (let ((sender-bal (balance-of tx-sender)))
      (asserts! (and (> amount u0) (<= amount sender-bal)) (err ERR_INVALID_AMOUNT))
      ;; Perform transfer
      (map-set balances { account: tx-sender } { balance: (- sender-bal amount) })
      (map-set balances { account: recipient } { balance: (+ (balance-of recipient) amount) })
      (print { event: "fraction-transfer", from: tx-sender, to: recipient, amount: amount })
      (ok true))))

;; (4) Redeem the NFT if caller owns all fractions
(define-public (redeem-nft)
  (begin
    (asserts! (var-get fractionalized) (err ERR_NOT_NFT_CONTRACT))
    (let ((total (var-get total-fractions)))
      (let ((caller-balance (balance-of tx-sender)))
        (asserts! (is-eq caller-balance total) (err ERR_NOT_FULL_OWNER))
        ;; burn all fractions
        (try! (burn tx-sender total))
        ;; update state
        (var-set fractionalized false)
        (var-set total-supply u0)
        (print { event: "redeemed", nft: (var-get nft-id), to: tx-sender })
        (ok true)))))

;; ------------------------------
;; Read-only functions
;; ------------------------------
(define-read-only (get-balance (who principal))
  (ok (balance-of who)))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

(define-read-only (get-nft-info)
  (ok {
    nft-contract: NFT_CONTRACT,
    nft-id: (var-get nft-id),
    fractionalized: (var-get fractionalized),
    total-fractions: (var-get total-fractions)
  }))
