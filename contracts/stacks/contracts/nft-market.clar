;; NFTMarket - NFT Marketplace with Royalties
;; Clarity v4

(define-map nfts
    uint
    {
        creator: principal,
        owner: principal,
        uri: (string-utf8 256),
        price: uint,
        for-sale: bool,
        royalty-percent: uint
    }
)

(define-data-var next-token-id uint u0)

(define-public (mint (uri (string-utf8 256)) (royalty-percent uint))
    (let
        (
            (token-id (var-get next-token-id))
        )
        (map-set nfts token-id {
            creator: tx-sender,
            owner: tx-sender,
            uri: uri,
            price: u0,
            for-sale: false,
            royalty-percent: royalty-percent
        })
        (var-set next-token-id (+ token-id u1))
        (ok token-id)
    )
)

(define-public (list-for-sale (token-id uint) (price uint))
    (let
        (
            (nft (unwrap! (map-get? nfts token-id) (err u100)))
        )
        (asserts! (is-eq tx-sender (get owner nft)) (err u101))
        (map-set nfts token-id (merge nft { price: price, for-sale: true }))
        (ok true)
    )
)

(define-public (buy (token-id uint))
    (let
        (
            (nft (unwrap! (map-get? nfts token-id) (err u100)))
            (royalty (/ (* (get price nft) (get royalty-percent nft)) u10000))
            (seller-amount (- (get price nft) royalty))
        )
        (asserts! (get for-sale nft) (err u102))
        
        (try! (stx-transfer? royalty tx-sender (get creator nft)))
        (try! (stx-transfer? seller-amount tx-sender (get owner nft)))
        
        (map-set nfts token-id (merge nft { owner: tx-sender, for-sale: false }))
        (ok true)
    )
)
