
;; title: PaperSource
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for paper production and sustainable forestry verification
;; description: This contract enables tracking of paper products from forest origin through production to final delivery,
;;              ensuring transparency and sustainability in the supply chain.

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-BATCH (err u101))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u102))
(define-constant ERR-FOREST-NOT-FOUND (err u103))
(define-constant ERR-INVALID-STAGE (err u104))
(define-constant ERR-BATCH-NOT-FOUND (err u105))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Stage constants for supply chain tracking
(define-constant STAGE-HARVESTED u1)
(define-constant STAGE-PROCESSED u2)
(define-constant STAGE-MANUFACTURED u3)
(define-constant STAGE-QUALITY-CHECKED u4)
(define-constant STAGE-SHIPPED u5)
(define-constant STAGE-DELIVERED u6)

;; data vars
;;
(define-data-var next-batch-id uint u1)
(define-data-var next-forest-id uint u1)

;; data maps
;;

;; Forest information for sustainability tracking
(define-map forests
  { forest-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 200),
    certification: (string-ascii 50), ;; FSC, PEFC, SFI, etc.
    owner: principal,
    total-area: uint, ;; in hectares
    is-sustainable: bool,
    created-at: uint
  }
)

;; Paper batch tracking through supply chain
(define-map paper-batches
  { batch-id: uint }
  {
    forest-id: uint,
    harvest-date: uint,
    current-stage: uint,
    quantity: uint, ;; in tons
    paper-type: (string-ascii 50), ;; newsprint, cardboard, office paper, etc.
    processor: (optional principal),
    manufacturer: (optional principal),
    quality-inspector: (optional principal),
    shipper: (optional principal),
    final-destination: (optional (string-ascii 200)),
    created-by: principal,
    created-at: uint,
    last-updated: uint
  }
)

;; Stage history for each batch
(define-map batch-stage-history
  { batch-id: uint, stage: uint }
  {
    updated-by: principal,
    timestamp: uint,
    notes: (optional (string-ascii 500)),
    location: (optional (string-ascii 200))
  }
)

;; Quality check results
(define-map quality-checks
  { batch-id: uint }
  {
    inspector: principal,
    passed: bool,
    moisture-content: uint, ;; percentage * 100 (e.g., 875 = 8.75%)
    strength-rating: uint, ;; 1-10 scale
    contamination-level: uint, ;; ppm
    notes: (optional (string-ascii 500)),
    timestamp: uint
  }
)

;; Authorized users for different roles
(define-map authorized-users
  { user: principal }
  {
    role: (string-ascii 20), ;; "harvester", "processor", "manufacturer", "inspector", "shipper"
    authorized-by: principal,
    authorized-at: uint
  }
)

;; public functions
;;

;; Register a new sustainable forest
(define-public (register-forest (name (string-ascii 100))
                               (location (string-ascii 200))
                               (certification (string-ascii 50))
                               (total-area uint)
                               (is-sustainable bool))
  (let ((forest-id (var-get next-forest-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set forests
      { forest-id: forest-id }
      {
        name: name,
        location: location,
        certification: certification,
        owner: tx-sender,
        total-area: total-area,
        is-sustainable: is-sustainable,
        created-at: block-height
      }
    )
    (var-set next-forest-id (+ forest-id u1))
    (ok forest-id)
  )
)

;; Create a new paper batch from harvested materials
(define-public (create-batch (forest-id uint)
                           (quantity uint)
                           (paper-type (string-ascii 50)))
  (let ((batch-id (var-get next-batch-id))
        (forest-data (unwrap! (map-get? forests { forest-id: forest-id }) ERR-FOREST-NOT-FOUND)))
    (asserts! (> quantity u0) ERR-INVALID-BATCH)
    (asserts! (is-none (map-get? paper-batches { batch-id: batch-id })) ERR-BATCH-ALREADY-EXISTS)

    ;; Create the batch
    (map-set paper-batches
      { batch-id: batch-id }
      {
        forest-id: forest-id,
        harvest-date: block-height,
        current-stage: STAGE-HARVESTED,
        quantity: quantity,
        paper-type: paper-type,
        processor: none,
        manufacturer: none,
        quality-inspector: none,
        shipper: none,
        final-destination: none,
        created-by: tx-sender,
        created-at: block-height,
        last-updated: block-height
      }
    )

    ;; Record initial stage
    (map-set batch-stage-history
      { batch-id: batch-id, stage: STAGE-HARVESTED }
      {
        updated-by: tx-sender,
        timestamp: block-height,
        notes: (some "Initial harvest recorded"),
        location: (some (get location forest-data))
      }
    )

    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Update batch stage in the supply chain
(define-public (update-batch-stage (batch-id uint)
                                 (new-stage uint)
                                 (notes (optional (string-ascii 500)))
                                 (location (optional (string-ascii 200))))
  (let ((batch-data (unwrap! (map-get? paper-batches { batch-id: batch-id }) ERR-BATCH-NOT-FOUND)))
    (asserts! (<= new-stage STAGE-DELIVERED) ERR-INVALID-STAGE)
    (asserts! (> new-stage (get current-stage batch-data)) ERR-INVALID-STAGE)

    ;; Update batch with new stage
    (map-set paper-batches
      { batch-id: batch-id }
      (merge batch-data {
        current-stage: new-stage,
        last-updated: block-height
      })
    )

    ;; Record stage history
    (map-set batch-stage-history
      { batch-id: batch-id, stage: new-stage }
      {
        updated-by: tx-sender,
        timestamp: block-height,
        notes: notes,
        location: location
      }
    )

    (ok true)
  )
)

;; Assign roles in the supply chain
(define-public (assign-batch-role (batch-id uint)
                                (role (string-ascii 20))
                                (user principal))
  (let ((batch-data (unwrap! (map-get? paper-batches { batch-id: batch-id }) ERR-BATCH-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update batch with role assignment
    (map-set paper-batches
      { batch-id: batch-id }
      (if (is-eq role "processor")
        (merge batch-data { processor: (some user) })
        (if (is-eq role "manufacturer")
          (merge batch-data { manufacturer: (some user) })
          (if (is-eq role "inspector")
            (merge batch-data { quality-inspector: (some user) })
            (if (is-eq role "shipper")
              (merge batch-data { shipper: (some user) })
              batch-data
            )
          )
        )
      )
    )

    (ok true)
  )
)

;; Record quality check results
(define-public (record-quality-check (batch-id uint)
                                   (passed bool)
                                   (moisture-content uint)
                                   (strength-rating uint)
                                   (contamination-level uint)
                                   (notes (optional (string-ascii 500))))
  (let ((batch-data (unwrap! (map-get? paper-batches { batch-id: batch-id }) ERR-BATCH-NOT-FOUND)))
    ;; Only quality inspector or contract owner can record quality checks
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER)
                  (is-eq (some tx-sender) (get quality-inspector batch-data))) ERR-NOT-AUTHORIZED)

    (map-set quality-checks
      { batch-id: batch-id }
      {
        inspector: tx-sender,
        passed: passed,
        moisture-content: moisture-content,
        strength-rating: strength-rating,
        contamination-level: contamination-level,
        notes: notes,
        timestamp: block-height
      }
    )

    (ok true)
  )
)

;; Authorize users for specific roles
(define-public (authorize-user (user principal) (role (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-users
      { user: user }
      {
        role: role,
        authorized-by: tx-sender,
        authorized-at: block-height
      }
    )
    (ok true)
  )
)

;; read only functions
;;

;; Get forest information
(define-read-only (get-forest (forest-id uint))
  (map-get? forests { forest-id: forest-id })
)

;; Get batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? paper-batches { batch-id: batch-id })
)

;; Get batch stage history
(define-read-only (get-batch-stage-history (batch-id uint) (stage uint))
  (map-get? batch-stage-history { batch-id: batch-id, stage: stage })
)

;; Get quality check results
(define-read-only (get-quality-check (batch-id uint))
  (map-get? quality-checks { batch-id: batch-id })
)

;; Get user authorization
(define-read-only (get-user-authorization (user principal))
  (map-get? authorized-users { user: user })
)

;; Check if forest is sustainable
(define-read-only (is-forest-sustainable (forest-id uint))
  (match (map-get? forests { forest-id: forest-id })
    forest-data (ok (get is-sustainable forest-data))
    ERR-FOREST-NOT-FOUND
  )
)

;; Get batch sustainability status (based on source forest)
(define-read-only (get-batch-sustainability (batch-id uint))
  (match (map-get? paper-batches { batch-id: batch-id })
    batch-data
      (match (map-get? forests { forest-id: (get forest-id batch-data) })
        forest-data (ok (get is-sustainable forest-data))
        ERR-FOREST-NOT-FOUND
      )
    ERR-BATCH-NOT-FOUND
  )
)

;; Get next available batch ID
(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

;; Get next available forest ID
(define-read-only (get-next-forest-id)
  (var-get next-forest-id)
)

;; private functions
;;

;; Validate stage transition (could be expanded for more complex business rules)
(define-private (is-valid-stage-transition (current-stage uint) (new-stage uint))
  (and (> new-stage current-stage)
       (<= new-stage STAGE-DELIVERED)
       (>= new-stage STAGE-HARVESTED)
  )
)

