-- name: CreateCustomer :one
INSERT INTO customers (
  first_name,
  last_name,
  date_of_birth,
  gender,
  email,
  phone_number,
  aadhaar_number,
  pan_number,
  address,
  city,
  state,
  pincode,
  kyc_status,
  customer_status
)
VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
)
RETURNING
  id,
  customer_code,
  first_name,
  last_name,
  email,
  phone_number,
  date_of_birth,
  gender,
  kyc_status,
  customer_status,
  created_at;

-- name: GetCustomerByID :one
SELECT
  id,
  customer_code,
  first_name,
  last_name,
  email,
  phone_number,
  date_of_birth,
  gender,
  address,
  city,
  state,
  pincode,
  kyc_status,
  customer_status,
  created_at,
  updated_at
FROM customers
WHERE id = $1 AND deleted_at IS NULL;

-- name: GetCustomerByAadhaar :one
SELECT
  id,
  customer_code,
  first_name,
  last_name,
  email,
  phone_number,
  aadhaar_number,
  kyc_status,
  customer_status
FROM customers
WHERE aadhaar_number = $1 AND deleted_at IS NULL;

-- name: UpdateCustomerStatus :exec
UPDATE customers
SET
  customer_status = $2,
  updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;

-- name: UpdateCustomerKYCStatus :exec
UPDATE customers
SET
  kyc_status = $2,
  updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;

-- name: ListActiveCustomers :many
SELECT
  id,
  customer_code,
  first_name,
  last_name,
  phone_number,
  email,
  kyc_status,
  customer_status,
  created_at
FROM customers
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: SearchCustomersByName :many
SELECT
  id,
  customer_code,
  first_name,
  last_name,
  email,
  phone_number,
  kyc_status,
  customer_status
FROM customers
WHERE deleted_at IS NULL
  AND (
    first_name ILIKE '%' || $1 || '%'
    OR last_name ILIKE '%' || $1 || '%'
  )
ORDER BY first_name
LIMIT $2 OFFSET $3;

-- name: DeleteCustomer :exec
UPDATE customers
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;

-- name: CreateKYCDocument :one
INSERT INTO kyc_documents (
  customer_id,
  document_type,
  document_number,
  document_file_path,
  verification_status
)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, customer_id, document_type, document_number, verification_status, created_at;

-- name: ListKYCDocumentsByCustomer :many
SELECT
  id,
  document_type,
  document_number,
  document_file_path,
  verification_status,
  created_at
FROM kyc_documents
WHERE customer_id = $1
ORDER BY created_at DESC;
