;; DecentralAuction: Decentralized Auction Platform for Digital Assets
;; This contract implements a decentralized auction system where:
;; 1. Users can create auctions for their digital assets
;; 2. Bidders can place bids on active auctions
;; 3. Auction winners can claim their assets when auctions end
;; 4. Auction creators receive payment when auctions conclude

(define-constant contract-owner tx-sender)

;; Error codes
(define-constant error-unauthorized (err u100))
(define-constant error-auction-exists (err u101))
(define-constant error-auction-not-found (err u102))
(define-constant error-auction-ended (err u103))
(define-constant error-auction-not-ended (err u104))
(define-constant error-bid-too-low (err u105))
(define-constant error-not-highest-bidder (err u106))
(define-constant error-not-auction-creator (err u107))
(define-constant error-asset-already-claimed (err u108))
(define-constant error-invalid-auction-duration (err u109))
(define-constant error-invalid-starting-price (err u110))
(define-constant error-not-contract-owner (err u111))
(define-constant error-auction-not-active (err u112))

;; Data structures
(define-map auctions
  { auction-id: uint }
  {
    creator: principal,
    asset-name: (string-ascii 64),
    asset-description: (string-ascii 256),
    asset-uri: (string-ascii 256),
    start-block: uint,
    end-block: uint,
    starting-price: uint,
    highest-bid: uint,
    highest-bidder: (optional principal),
    is-active: bool,
    is-claimed: bool
  }
)

(define-map bids
  { auction-id: uint, bidder: principal }
  { amount: uint, block-height: uint }
)

;; Counter for auction IDs
(define-data-var next-auction-id uint u1)

;; Platform fee percentage (5% = 500 basis points)
(define-data-var platform-fee-bps uint u500)

;; Read-only functions

;; Get auction details
(define-read-only (get-auction (auction-id uint))
  (map-get? auctions { auction-id: auction-id })
)

;; Get bid details
(define-read-only (get-bid (auction-id uint) (bidder principal))
  (map-get? bids { auction-id: auction-id, bidder: bidder })
)

;; Check if an auction exists
(define-read-only (auction-exists (auction-id uint))
  (is-some (get-auction auction-id))
)

;; Check if an auction is active
(define-read-only (is-auction-active (auction-id uint))
  (match (get-auction auction-id)
    auction (and 
              (get is-active auction)
              (< block-height (get end-block auction))
            )
    false
  )
)

;; Check if an auction has ended
(define-read-only (has-auction-ended (auction-id uint))
  (match (get-auction auction-id)
    auction (>= block-height (get end-block auction))
    false
  )
)

;; Get current auction ID
(define-read-only (get-current-auction-id)
  (var-get next-auction-id)
)

;; Get platform fee percentage
(define-read-only (get-platform-fee-bps)
  (var-get platform-fee-bps)
)

;; Calculate platform fee amount
(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-bps)) u10000)
)

;; Helper functions

;; Calculate seller proceeds after platform fee
(define-private (calculate-seller-proceeds (amount uint))
  (- amount (calculate-platform-fee amount))
)

;; Public functions

;; Create a new auction
(define-public (create-auction 
                (asset-name (string-ascii 64))
                (asset-description (string-ascii 256))
                (asset-uri (string-ascii 256))
                (duration uint)
                (starting-price uint))
  (let ((auction-id (var-get next-auction-id))
        (start-block block-height)
        (end-block (+ block-height duration)))
    (begin
      ;; Validate inputs
      (asserts! (> duration u0) error-invalid-auction-duration)
      (asserts! (> starting-price u0) error-invalid-starting-price)
      
      ;; Create auction
      (map-set auctions
        { auction-id: auction-id }
        {
          creator: tx-sender,
          asset-name: asset-name,
          asset-description: asset-description,
          asset-uri: asset-uri,
          start-block: start-block,
          end-block: end-block,
          starting-price: starting-price,
          highest-bid: u0,
          highest-bidder: none,
          is-active: true,
          is-claimed: false
        }
      )
      
      ;; Increment auction ID
      (var-set next-auction-id (+ auction-id u1))
      
      (ok auction-id)
    )
  )
)

;; Place a bid on an auction
(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let ((auction (unwrap! (get-auction auction-id) error-auction-not-found)))
    (begin
      ;; Check auction is active
      (asserts! (get is-active auction) error-auction-not-active)
      (asserts! (< block-height (get end-block auction)) error-auction-ended)
      
      ;; Check bid amount
      (asserts! (if (is-some (get highest-bidder auction))
                   (> bid-amount (get highest-bid auction))
                   (>= bid-amount (get starting-price auction)))
               error-bid-too-low)
      
      ;; Record the bid
      (map-set bids
        { auction-id: auction-id, bidder: tx-sender }
        { amount: bid-amount, block-height: block-height }
      )
      
      ;; Update auction with new highest bid
      (map-set auctions
        { auction-id: auction-id }
        (merge auction {
          highest-bid: bid-amount,
          highest-bidder: (some tx-sender)
        })
      )
      
      (ok true)
    )
  )
)

;; End an auction early (only by creator)
(define-public (end-auction-early (auction-id uint))
  (let ((auction (unwrap! (get-auction auction-id) error-auction-not-found)))
    (begin
      ;; Check sender is auction creator
      (asserts! (is-eq tx-sender (get creator auction)) error-not-auction-creator)
      
      ;; Check auction is active
      (asserts! (get is-active auction) error-auction-not-active)
      (asserts! (< block-height (get end-block auction)) error-auction-ended)
      
      ;; Update auction to mark as inactive but not claimed
      (map-set auctions
        { auction-id: auction-id }
        (merge auction {
          is-active: false,
          end-block: block-height
        })
      )
      
      (ok true)
    )
  )
)

;; Claim asset (for winning bidder)
(define-public (claim-asset (auction-id uint))
  (let ((auction (unwrap! (get-auction auction-id) error-auction-not-found)))
    (begin
      ;; Check auction has ended
      (asserts! (>= block-height (get end-block auction)) error-auction-not-ended)
      
      ;; Check sender is highest bidder
      (asserts! (is-eq (some tx-sender) (get highest-bidder auction)) error-not-highest-bidder)
      
      ;; Check asset not already claimed
      (asserts! (not (get is-claimed auction)) error-asset-already-claimed)
      
      ;; Calculate fees
      (let ((bid-amount (get highest-bid auction))
            (platform-fee (calculate-platform-fee (get highest-bid auction)))
            (seller-proceeds (calculate-seller-proceeds (get highest-bid auction))))
        
        ;; Update auction as claimed
        (map-set auctions
          { auction-id: auction-id }
          (merge auction { is-claimed: true })
        )
        
        ;; Handle payment to creator
        (stx-transfer? seller-proceeds tx-sender (get creator auction))
        
        ;; Handle platform fee
        (stx-transfer? platform-fee tx-sender contract-owner)
        
        (ok true)
      )
    )
  )
)

;; Cancel auction (only by creator and only if no bids)
(define-public (cancel-auction (auction-id uint))
  (let ((auction (unwrap! (get-auction auction-id) error-auction-not-found)))
    (begin
      ;; Check sender is auction creator
      (asserts! (is-eq tx-sender (get creator auction)) error-not-auction-creator)
      
      ;; Check auction is active
      (asserts! (get is-active auction) error-auction-not-active)
      
      ;; Check no bids have been placed
      (asserts! (is-eq (get highest-bid auction) u0) error-bid-too-low)
      
      ;; Update auction to mark as inactive
      (map-set auctions
        { auction-id: auction-id }
        (merge auction { is-active: false })
      )
      
      (ok true)
    )
  )
)

;; Admin functions

;; Update platform fee (only by contract owner)
(define-public (update-platform-fee (new-fee-bps uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) error-not-contract-owner)
    (asserts! (<= new-fee-bps u1000) error-unauthorized)  ;; Max 10%
    (ok (var-set platform-fee-bps new-fee-bps))
  )
)

;; Transfer contract ownership (only by current owner)
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) error-not-contract-owner)
    (ok (var-set contract-owner new-owner))
  )
)