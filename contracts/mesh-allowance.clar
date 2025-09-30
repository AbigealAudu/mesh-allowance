;; mesh-allowance
;;
;; A decentralized spending allowance management contract that enables secure,
;; transparent financial tracking and controlled spending across multiple 
;; principals with customizable allocation and permission rules.
;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u2001))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2002))
(define-constant ERR-INVALID-ALLOCATION (err u2003))
(define-constant ERR-ALLOWANCE-NOT-FOUND (err u2004))
(define-constant ERR-INVALID-AMOUNT (err u2005))
;; Data Maps and Variables
;; Store allowance configurations
(define-map allowances
  {
    owner: principal,
    spender: principal,
  }
  {
    total-limit: uint,
    spent-amount: uint,
    last-updated: uint,
  }
)
;; Store detailed transaction history
(define-map transaction-history
  {
    owner: principal,
    spender: principal,
    transaction-id: uint,
  }
  {
    amount: uint,
    timestamp: uint,
    description: (string-utf8 100),
  }
)
;; Store additional permissions and rules
(define-map allowance-rules
  {
    owner: principal,
    spender: principal,
  }
  {
    can-modify: bool,
    expiration: uint,
    requires-approval: bool,
  }
)
;; Private Functions
;; Check authorization and spending limits
(define-private (check-spending-authorization
    (owner principal)
    (spender principal)
    (amount uint)
  )
  (let (
      (allowance-data (unwrap!
        (map-get? allowances {
          owner: owner,
          spender: spender,
        })
        ERR-ALLOWANCE-NOT-FOUND
      ))
      (current-limit (get total-limit allowance-data))
      (spent-amount (get spent-amount allowance-data))
    )
    (if (<= (+ spent-amount amount) current-limit)
      (ok true)
      ERR-INSUFFICIENT-FUNDS
    )
  )
)

;; Update spent amount for an allowance
(define-private (update-spent-amount
    (owner principal)
    (spender principal)
    (amount uint)
  )
  (let (
      (current-allowance (unwrap-panic (map-get? allowances {
        owner: owner,
        spender: spender,
      })))
      (new-spent-amount (+ (get spent-amount current-allowance) amount))
    )
    (map-set allowances {
      owner: owner,
      spender: spender,
    }
      (merge current-allowance {
        spent-amount: new-spent-amount,
        last-updated: (unwrap-panic (get-block-info? time u0)),
      })
    )
    (ok new-spent-amount)
  )
)


;; Public Functions
;; Set a new spending allowance
(define-public (set-allowance
    (spender principal)
    (total-limit uint)
    (description (optional (string-utf8 100)))
  )
  (begin
    (asserts! (> total-limit u0) ERR-INVALID-ALLOCATION)
    (map-set allowances {
      owner: tx-sender,
      spender: spender,
    } {
      total-limit: total-limit,
      spent-amount: u0,
      last-updated: (unwrap-panic (get-block-info? time u0)),
    })
    (map-set allowance-rules {
      owner: tx-sender,
      spender: spender,
    } {
      can-modify: true,
      expiration: u0, ;; No expiration by default
      requires-approval: false,
    })
    (ok true)
  )
)


;; Modify existing allowance configuration
(define-public (modify-allowance
    (spender principal)
    (new-limit uint)
  )
  (let (
      (current-allowance (unwrap!
        (map-get? allowances {
          owner: tx-sender,
          spender: spender,
        })
        ERR-ALLOWANCE-NOT-FOUND
      ))
      (current-rules (unwrap!
        (map-get? allowance-rules {
          owner: tx-sender,
          spender: spender,
        })
        ERR-NOT-AUTHORIZED
      ))
    )
    (asserts! (get can-modify current-rules) ERR-NOT-AUTHORIZED)
    (map-set allowances {
      owner: tx-sender,
      spender: spender,
    }
      (merge current-allowance {
        total-limit: new-limit,
        last-updated: (unwrap-panic (get-block-info? time u0)),
      })
    )
    (ok true)
  )
)

;; Read-Only Functions
;; Get current allowance details
(define-read-only (get-allowance-details
    (owner principal)
    (spender principal)
  )
  (map-get? allowances {
    owner: owner,
    spender: spender,
  })
)
