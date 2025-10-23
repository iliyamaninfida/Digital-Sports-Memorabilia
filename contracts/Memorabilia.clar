(impl-trait .sip-009-nft-trait.sip-009-nft-trait)

(define-non-fungible-token memorabilia uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-not-found (err u102))
(define-constant err-not-authorized (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-max-supply-reached (err u106))
(define-constant err-not-for-sale (err u107))
(define-constant err-insufficient-funds (err u108))
(define-constant err-transfer-failed (err u109))
(define-constant err-offer-not-found (err u110))
(define-constant err-offer-expired (err u111))
(define-constant err-offer-exists (err u112))

(define-data-var token-id-nonce uint u0)

(define-map token-metadata uint {
  athlete: (string-ascii 100),
  sport: (string-ascii 50),
  description: (string-ascii 500),
  rarity: (string-ascii 20),
  edition-number: uint,
  total-editions: uint,
  creation-timestamp: uint,
  uri: (string-ascii 256)
})

(define-map token-authenticity uint {
  verified: bool,
  verifier: principal,
  verification-date: uint
})

(define-map verified-creators principal bool)

(define-map collection-max-supply {athlete: (string-ascii 100), item-type: (string-ascii 500)} uint)
(define-map collection-current-supply {athlete: (string-ascii 100), item-type: (string-ascii 500)} uint)

(define-map marketplace uint {
  price: uint,
  seller: principal,
  listed-at: uint
})

(define-map token-royalties uint {
  creator: principal,
  percentage: uint
})

(define-map token-offers {token-id: uint, offerer: principal} {
  amount: uint,
  expiration: uint,
  created-at: uint
})

(define-map offer-escrow {token-id: uint, offerer: principal} uint)

(define-public (set-verified-creator (creator principal) (verified bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set verified-creators creator verified)
    (ok true)
  )
)

(define-public (mint-memorabilia 
  (recipient principal)
  (athlete (string-ascii 100))
  (sport (string-ascii 50))
  (description (string-ascii 500))
  (rarity (string-ascii 20))
  (max-editions uint)
  (uri (string-ascii 256))
  (royalty-percentage uint))
  (let (
    (token-id (+ (var-get token-id-nonce) u1))
    (collection-key {athlete: athlete, item-type: description})
    (current-supply (default-to u0 (map-get? collection-current-supply collection-key)))
    (max-supply (default-to u0 (map-get? collection-max-supply collection-key)))
    (creation-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
  )
    (asserts! (default-to false (map-get? verified-creators tx-sender)) err-not-authorized)
    (asserts! (<= royalty-percentage u1000) err-invalid-params)
    
    (if (is-eq max-supply u0)
      (map-set collection-max-supply collection-key max-editions)
      true
    )
    
    (asserts! (< current-supply (unwrap-panic (map-get? collection-max-supply collection-key))) err-max-supply-reached)
    
    (try! (nft-mint? memorabilia token-id recipient))
    
    (map-set token-metadata token-id {
      athlete: athlete,
      sport: sport,
      description: description,
      rarity: rarity,
      edition-number: (+ current-supply u1),
      total-editions: (unwrap-panic (map-get? collection-max-supply collection-key)),
      creation-timestamp: creation-time,
      uri: uri
    })
    
    (map-set token-authenticity token-id {
      verified: true,
      verifier: tx-sender,
      verification-date: creation-time
    })
    
    (map-set token-royalties token-id {
      creator: tx-sender,
      percentage: royalty-percentage
    })
    
    (map-set collection-current-supply collection-key (+ current-supply u1))
    (var-set token-id-nonce token-id)
    (ok token-id)
  )
)

(define-public (verify-authenticity (token-id uint))
  (let (
    (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
  )
    (asserts! (is-some (nft-get-owner? memorabilia token-id)) err-not-found)
    (asserts! (default-to false (map-get? verified-creators tx-sender)) err-not-authorized)
    
    (map-set token-authenticity token-id {
      verified: true,
      verifier: tx-sender,
      verification-date: current-time
    })
    (ok true)
  )
)

(define-public (list-for-sale (token-id uint) (price uint))
  (let (
    (owner (unwrap! (nft-get-owner? memorabilia token-id) err-not-found))
  )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> price u0) err-invalid-params)
    
    (map-set marketplace token-id {
      price: price,
      seller: tx-sender,
      listed-at: (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1)))
    })
    (ok true)
  )
)

(define-public (unlist-from-sale (token-id uint))
  (let (
    (listing (unwrap! (map-get? marketplace token-id) err-not-for-sale))
  )
    (asserts! (is-eq tx-sender (get seller listing)) err-not-authorized)
    (map-delete marketplace token-id)
    (ok true)
  )
)

(define-public (buy-memorabilia (token-id uint))
  (let (
    (listing (unwrap! (map-get? marketplace token-id) err-not-for-sale))
    (price (get price listing))
    (seller (get seller listing))
    (royalty-info (map-get? token-royalties token-id))
  )
    (match royalty-info
      royalty-data
      (let (
        (creator (get creator royalty-data))
        (royalty-amount (/ (* price (get percentage royalty-data)) u10000))
        (seller-amount (- price royalty-amount))
      )
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? royalty-amount tx-sender creator)))
        (try! (as-contract (stx-transfer? seller-amount tx-sender seller)))
        (try! (nft-transfer? memorabilia token-id seller tx-sender))
        (map-delete marketplace token-id)
        (ok true)
      )
      (begin
        (try! (stx-transfer? price tx-sender seller))
        (try! (nft-transfer? memorabilia token-id seller tx-sender))
        (map-delete marketplace token-id)
        (ok true)
      )
    )
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-authorized)
    (try! (nft-transfer? memorabilia token-id sender recipient))
    (map-delete marketplace token-id)
    (ok true)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some (get uri (unwrap! (map-get? token-metadata token-id) err-not-found))))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? memorabilia token-id))
)

(define-read-only (get-token-metadata (token-id uint))
  (ok (map-get? token-metadata token-id))
)

(define-read-only (get-token-authenticity (token-id uint))
  (ok (map-get? token-authenticity token-id))
)

(define-read-only (get-marketplace-listing (token-id uint))
  (ok (map-get? marketplace token-id))
)

(define-read-only (is-verified-creator (creator principal))
  (ok (default-to false (map-get? verified-creators creator)))
)

(define-read-only (get-collection-info (athlete (string-ascii 100)) (item-type (string-ascii 500)))
  (let (
    (collection-key {athlete: athlete, item-type: item-type})
  )
    (ok {
      max-supply: (default-to u0 (map-get? collection-max-supply collection-key)),
      current-supply: (default-to u0 (map-get? collection-current-supply collection-key))
    })
  )
)

(define-read-only (get-token-royalty (token-id uint))
  (ok (map-get? token-royalties token-id))
)

(define-public (make-offer (token-id uint) (amount uint) (duration-blocks uint))
  (let (
    (owner (unwrap! (nft-get-owner? memorabilia token-id) err-not-found))
    (current-height stacks-block-height)
    (expiration (+ current-height duration-blocks))
    (offer-key {token-id: token-id, offerer: tx-sender})
  )
    (asserts! (> amount u0) err-invalid-params)
    (asserts! (> duration-blocks u0) err-invalid-params)
    (asserts! (not (is-eq tx-sender owner)) err-not-authorized)
    (asserts! (is-none (map-get? token-offers offer-key)) err-offer-exists)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set token-offers offer-key {
      amount: amount,
      expiration: expiration,
      created-at: current-height
    })
    (map-set offer-escrow offer-key amount)
    (ok true)
  )
)

(define-public (cancel-offer (token-id uint))
  (let (
    (offer-key {token-id: token-id, offerer: tx-sender})
    (offer (unwrap! (map-get? token-offers offer-key) err-offer-not-found))
    (escrowed-amount (unwrap! (map-get? offer-escrow offer-key) err-offer-not-found))
  )
    (try! (as-contract (stx-transfer? escrowed-amount tx-sender tx-sender)))
    (map-delete token-offers offer-key)
    (map-delete offer-escrow offer-key)
    (ok escrowed-amount)
  )
)

(define-public (accept-offer (token-id uint) (offerer principal))
  (let (
    (owner (unwrap! (nft-get-owner? memorabilia token-id) err-not-found))
    (offer-key {token-id: token-id, offerer: offerer})
    (offer (unwrap! (map-get? token-offers offer-key) err-offer-not-found))
    (amount (get amount offer))
    (expiration (get expiration offer))
    (escrowed-amount (unwrap! (map-get? offer-escrow offer-key) err-offer-not-found))
    (royalty-info (map-get? token-royalties token-id))
  )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (< stacks-block-height expiration) err-offer-expired)
    (match royalty-info
      royalty-data
      (let (
        (creator (get creator royalty-data))
        (royalty-amount (/ (* amount (get percentage royalty-data)) u10000))
        (seller-amount (- amount royalty-amount))
      )
        (try! (as-contract (stx-transfer? royalty-amount tx-sender creator)))
        (try! (as-contract (stx-transfer? seller-amount tx-sender owner)))
        (try! (nft-transfer? memorabilia token-id owner offerer))
        (map-delete marketplace token-id)
        (map-delete token-offers offer-key)
        (map-delete offer-escrow offer-key)
        (ok true)
      )
      (begin
        (try! (as-contract (stx-transfer? amount tx-sender owner)))
        (try! (nft-transfer? memorabilia token-id owner offerer))
        (map-delete marketplace token-id)
        (map-delete token-offers offer-key)
        (map-delete offer-escrow offer-key)
        (ok true)
      )
    )
  )
)

(define-public (reject-offer (token-id uint) (offerer principal))
  (let (
    (owner (unwrap! (nft-get-owner? memorabilia token-id) err-not-found))
    (offer-key {token-id: token-id, offerer: offerer})
    (offer (unwrap! (map-get? token-offers offer-key) err-offer-not-found))
    (escrowed-amount (unwrap! (map-get? offer-escrow offer-key) err-offer-not-found))
  )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (try! (as-contract (stx-transfer? escrowed-amount tx-sender offerer)))
    (map-delete token-offers offer-key)
    (map-delete offer-escrow offer-key)
    (ok true)
  )
)

(define-read-only (get-offer (token-id uint) (offerer principal))
  (ok (map-get? token-offers {token-id: token-id, offerer: offerer}))
)

(define-read-only (get-offer-escrow (token-id uint) (offerer principal))
  (ok (map-get? offer-escrow {token-id: token-id, offerer: offerer}))
)
