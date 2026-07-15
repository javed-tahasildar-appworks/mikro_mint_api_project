CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  customer_code TEXT UNIQUE DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  date_of_birth DATE,
  gender TEXT,
  email TEXT UNIQUE,
  phone_number TEXT,
  aadhaar_number TEXT,
  pan_number TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  pincode TEXT,
  kyc_status TEXT DEFAULT 'pending',
  customer_status TEXT DEFAULT 'active',
  deleted_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE kyc_documents (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  document_type TEXT,
  document_number TEXT,
  document_file_path TEXT,
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
