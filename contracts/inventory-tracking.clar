;; Inventory Tracking Contract
;; Monitors stock levels across retail locations

(define-data-var admin principal tx-sender)

;; Inventory data map: store-id + product-id -> inventory data
(define-map inventory
  { store-id: uint, product-id: uint }
  {
    quantity: uint,
    last-updated: uint
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Update inventory for a product at a store
(define-public (update-inventory (store-id uint) (product-id uint) (quantity uint))
  (let
    (
      (block-time (unwrap-panic (get-block-info? time u0)))
    )
    (asserts! (is-admin) (err u403))
    ;; Note: In a real implementation, we would check if store and product are active
    ;; but keeping it simple for this example
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: quantity,
        last-updated: block-time
      }
    )
    (ok true)
  )
)

;; Add to inventory (increase quantity)
(define-public (add-inventory (store-id uint) (product-id uint) (amount uint))
  (let
    (
      (current-inventory (default-to { quantity: u0, last-updated: u0 }
                          (map-get? inventory { store-id: store-id, product-id: product-id })))
      (new-quantity (+ (get quantity current-inventory) amount))
      (block-time (unwrap-panic (get-block-info? time u0)))
    )
    (asserts! (is-admin) (err u403))
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: new-quantity,
        last-updated: block-time
      }
    )
    (ok new-quantity)
  )
)

;; Remove from inventory (decrease quantity)
(define-public (remove-inventory (store-id uint) (product-id uint) (amount uint))
  (let
    (
      (current-inventory (default-to { quantity: u0, last-updated: u0 }
                          (map-get? inventory { store-id: store-id, product-id: product-id })))
      (current-quantity (get quantity current-inventory))
      (block-time (unwrap-panic (get-block-info? time u0)))
    )
    (asserts! (is-admin) (err u403))
    (asserts! (>= current-quantity amount) (err u400))
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: (- current-quantity amount),
        last-updated: block-time
      }
    )
    (ok (- current-quantity amount))
  )
)

;; Get inventory level for a product at a store
(define-read-only (get-inventory (store-id uint) (product-id uint))
  (default-to { quantity: u0, last-updated: u0 }
    (map-get? inventory { store-id: store-id, product-id: product-id })
  )
)

;; Check if product is in stock at a store
(define-read-only (is-in-stock (store-id uint) (product-id uint) (required-quantity uint))
  (let
    (
      (current-inventory (get-inventory store-id product-id))
    )
    (>= (get quantity current-inventory) required-quantity)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
