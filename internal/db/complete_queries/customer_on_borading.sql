-- =====================================================
-- MICROFINANCE CUSTOMER MANAGEMENT MODULE
-- PostgreSQL 17 Compatible - Production Ready
-- =====================================================
-- Version: 2.0 (Fixed & Tested)
-- Execute this script as-is in PostgreSQL 17
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- =====================================================
-- 1. DROP EXISTING OBJECTS (Clean slate)
-- =====================================================

DROP VIEW IF EXISTS vw_query_performance CASCADE;
DROP VIEW IF EXISTS vw_table_sizes CASCADE;
DROP VIEW IF EXISTS vw_duplicate_customers CASCADE;
DROP VIEW IF EXISTS vw_agent_onboarding_performance CASCADE;
DROP VIEW IF EXISTS vw_daily_onboarding_stats CASCADE;
DROP VIEW IF EXISTS vw_expiring_documents CASCADE;
DROP VIEW IF EXISTS vw_customer_complete_profile CASCADE;
DROP VIEW IF EXISTS vw_pending_kyc_customers CASCADE;
DROP VIEW IF EXISTS vw_active_customers CASCADE;

DROP TABLE IF EXISTS address_history CASCADE;
DROP TABLE IF EXISTS customer_audit_log CASCADE;
DROP TABLE IF EXISTS customer_approvals CASCADE;
DROP TABLE IF EXISTS kyc_verifications CASCADE;
DROP TABLE IF EXISTS customer_nominees CASCADE;
DROP TABLE IF EXISTS customer_documents CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

DROP TYPE IF EXISTS approval_status CASCADE;
DROP TYPE IF EXISTS employment_type CASCADE;
DROP TYPE IF EXISTS marital_status CASCADE;
DROP TYPE IF EXISTS gender_type CASCADE;
DROP TYPE IF EXISTS address_type CASCADE;
DROP TYPE IF EXISTS document_status CASCADE;
DROP TYPE IF EXISTS document_type CASCADE;
DROP TYPE IF EXISTS kyc_status CASCADE;
DROP TYPE IF EXISTS customer_status CASCADE;

-- =====================================================
-- 2. CREATE ENUMS & TYPES
-- =====================================================

CREATE TYPE customer_status AS ENUM (
    'pending_verification',
    'kyc_submitted',
    'kyc_approved',
    'active',
    'inactive',
    'suspended',
    'blacklisted',
    'deceased'
);

CREATE TYPE kyc_status AS ENUM (
    'not_started',
    'in_progress',
    'submitted',
    'under_review',
    'approved',
    'rejected',
    'expired',
    'resubmission_required'
);

CREATE TYPE document_type AS ENUM (
    'aadhaar_front',
    'aadhaar_back',
    'pan_card',
    'voter_id',
    'passport',
    'driving_license',
    'bank_statement',
    'income_proof',
    'address_proof',
    'photo',
    'signature',
    'other'
);

CREATE TYPE document_status AS ENUM (
    'pending_upload',
    'uploaded',
    'under_verification',
    'verified',
    'rejected',
    'expired'
);

CREATE TYPE address_type AS ENUM (
    'permanent',
    'current',
    'communication',
    'business',
    'office'
);

CREATE TYPE gender_type AS ENUM (
    'male', 
    'female', 
    'other', 
    'prefer_not_to_say'
);

CREATE TYPE marital_status AS ENUM (
    'single',
    'married',
    'divorced',
    'widowed',
    'separated'
);

CREATE TYPE employment_type AS ENUM (
    'self_employed',
    'salaried',
    'business_owner',
    'daily_wage',
    'agricultural',
    'retired',
    'homemaker',
    'student',
    'unemployed'
);

CREATE TYPE approval_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'on_hold',
    'resubmit_required'
);

-- =====================================================
-- 3. CORE TABLES
-- =====================================================

-- Customers Master Table
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender gender_type NOT NULL,
    marital_status marital_status,
    
    -- Contact Information
    mobile_primary VARCHAR(15) NOT NULL UNIQUE,
    mobile_secondary VARCHAR(15),
    email VARCHAR(255),
    alternate_email VARCHAR(255),
    
    -- Employment & Financial
    occupation VARCHAR(100),
    employment_type employment_type,
    monthly_income DECIMAL(15,2),
    annual_income DECIMAL(15,2),
    
    -- Identity Numbers
    aadhaar_number VARCHAR(12) UNIQUE,
    pan_number VARCHAR(10) UNIQUE,
    voter_id VARCHAR(20),
    
    -- Status & Flags
    status customer_status DEFAULT 'pending_verification' NOT NULL,
    kyc_status kyc_status DEFAULT 'not_started' NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_verified BOOLEAN DEFAULT false NOT NULL,
    
    -- Risk & Credit
    credit_score INTEGER CHECK (credit_score >= 300 AND credit_score <= 900),
    risk_category VARCHAR(20),
    
    -- Metadata
    onboarded_by BIGINT,
    onboarded_at TIMESTAMP WITH TIME ZONE,
    verified_by BIGINT,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by BIGINT,
    updated_by BIGINT,
    deleted_by BIGINT,
    
    -- Search optimization
    search_vector tsvector,
    
    -- Constraints
    CONSTRAINT valid_aadhaar CHECK (aadhaar_number IS NULL OR aadhaar_number ~ '^[0-9]{12}$'),
    CONSTRAINT valid_pan CHECK (pan_number IS NULL OR pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'),
    CONSTRAINT valid_mobile CHECK (mobile_primary ~ '^[0-9]{10,15}$'),
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    CONSTRAINT valid_dob CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years')
);

-- Customer Addresses
CREATE TABLE customer_addresses (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_type address_type NOT NULL,
    
    -- Address Components
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    landmark VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    country VARCHAR(100) DEFAULT 'India' NOT NULL,
    
    -- Geolocation
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Status
    is_primary BOOLEAN DEFAULT false NOT NULL,
    is_verified BOOLEAN DEFAULT false NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by BIGINT,
    
    -- Validity
    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT valid_pincode CHECK (pincode ~ '^[0-9]{6}$'),
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
);

-- Customer Documents
CREATE TABLE customer_documents (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    document_type document_type NOT NULL,
    
    -- Document Details
    document_number VARCHAR(50),
    document_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    file_size_kb INTEGER,
    
    -- Storage Info
    storage_path TEXT,
    storage_bucket VARCHAR(255),
    
    -- Status & Verification
    status document_status DEFAULT 'uploaded' NOT NULL,
    is_verified BOOLEAN DEFAULT false NOT NULL,
    verified_by BIGINT,
    verified_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Validity
    issued_date DATE,
    expiry_date DATE,
    
    -- Versioning
    version INTEGER DEFAULT 1 NOT NULL,
    parent_document_id BIGINT REFERENCES customer_documents(id),
    is_latest BOOLEAN DEFAULT true NOT NULL,
    replaced_at TIMESTAMP WITH TIME ZONE,
    replaced_by BIGINT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT valid_expiry CHECK (expiry_date IS NULL OR expiry_date > issued_date)
);

-- Customer Nominees
CREATE TABLE customer_nominees (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Nominee Details
    nominee_name VARCHAR(200) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    mobile_number VARCHAR(15),
    email VARCHAR(255),
    
    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    
    -- Allocation
    share_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    is_primary BOOLEAN DEFAULT false NOT NULL,
    
    -- Identity
    aadhaar_number VARCHAR(12),
    pan_number VARCHAR(10),
    
    -- Status
    is_active BOOLEAN DEFAULT true NOT NULL,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT valid_share_percentage CHECK (share_percentage > 0 AND share_percentage <= 100),
    CONSTRAINT valid_nominee_mobile CHECK (mobile_number IS NULL OR mobile_number ~ '^[0-9]{10,15}$')
);

-- KYC Verification Workflow
CREATE TABLE kyc_verifications (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Verification Details
    verification_type VARCHAR(50) NOT NULL,
    verification_status approval_status DEFAULT 'pending' NOT NULL,
    
    -- Checklist
    aadhaar_verified BOOLEAN DEFAULT false,
    pan_verified BOOLEAN DEFAULT false,
    address_verified BOOLEAN DEFAULT false,
    photo_verified BOOLEAN DEFAULT false,
    biometric_verified BOOLEAN DEFAULT false,
    
    -- External API Results
    digilocker_response JSONB,
    aadhaar_xml_verified BOOLEAN DEFAULT false,
    pan_verification_response JSONB,
    
    -- Review
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewer_comments TEXT,
    rejection_reason TEXT,
    
    -- Approval Chain
    l1_approver BIGINT,
    l1_approved_at TIMESTAMP WITH TIME ZONE,
    l1_comments TEXT,
    l2_approver BIGINT,
    l2_approved_at TIMESTAMP WITH TIME ZONE,
    l2_comments TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Customer Approval Workflow
CREATE TABLE customer_approvals (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Workflow
    workflow_step VARCHAR(50) NOT NULL,
    approval_status approval_status DEFAULT 'pending' NOT NULL,
    
    -- Assigned To
    assigned_to BIGINT,
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Action
    actioned_by BIGINT,
    actioned_at TIMESTAMP WITH TIME ZONE,
    comments TEXT,
    rejection_reason TEXT,
    
    -- Next Step
    next_step VARCHAR(50),
    escalated_to BIGINT,
    escalated_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =====================================================
-- 4. AUDIT & HISTORY TABLES
-- =====================================================

-- Customer Audit Log (Partitioned)
CREATE TABLE customer_audit_log (
    id BIGSERIAL,
    customer_id BIGINT NOT NULL,
    
    -- Change Details
    table_name VARCHAR(100) NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    
    -- Context
    changed_by BIGINT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address INET,
    user_agent TEXT,
    
    -- Metadata
    transaction_id BIGINT,
    session_id VARCHAR(100),
    reason TEXT,
    
    PRIMARY KEY (id, changed_at)
) PARTITION BY RANGE (changed_at);

-- Create partitions for audit log
CREATE TABLE customer_audit_log_2024_q3 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE customer_audit_log_2024_q4 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE customer_audit_log_2025_q1 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE customer_audit_log_2025_q2 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE customer_audit_log_2025_q3 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

CREATE TABLE customer_audit_log_2025_q4 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

CREATE TABLE customer_audit_log_2026_q1 PARTITION OF customer_audit_log
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

-- Address Change History
CREATE TABLE address_history (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_id BIGINT,
    
    -- Historical Address
    address_type address_type NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    
    -- Period
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    
    -- Audit
    changed_by BIGINT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    change_reason TEXT
);

-- =====================================================
-- 5. INDEXES FOR PERFORMANCE
-- =====================================================

-- Customers indexes
CREATE INDEX idx_customers_customer_code ON customers(customer_code);
CREATE INDEX idx_customers_mobile ON customers(mobile_primary);
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL;
CREATE INDEX idx_customers_aadhaar ON customers(aadhaar_number) WHERE aadhaar_number IS NOT NULL;
CREATE INDEX idx_customers_pan ON customers(pan_number) WHERE pan_number IS NOT NULL;
CREATE INDEX idx_customers_status ON customers(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_kyc_status ON customers(kyc_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_active ON customers(is_active, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_created_at ON customers(created_at DESC);
CREATE INDEX idx_customers_onboarded_by ON customers(onboarded_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_search ON customers USING gin(search_vector);
CREATE INDEX idx_customers_name_trgm ON customers USING gin((first_name || ' ' || COALESCE(middle_name, '') || ' ' || last_name) gin_trgm_ops);
CREATE INDEX idx_customers_status_created ON customers(status, created_at DESC) WHERE deleted_at IS NULL;

-- Customer addresses indexes
CREATE INDEX idx_addresses_customer_id ON customer_addresses(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_addresses_type ON customer_addresses(customer_id, address_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_addresses_primary ON customer_addresses(customer_id, is_primary) WHERE is_primary = true AND deleted_at IS NULL;
CREATE INDEX idx_addresses_pincode ON customer_addresses(pincode) WHERE deleted_at IS NULL;
CREATE INDEX idx_addresses_city_state ON customer_addresses(city, state) WHERE deleted_at IS NULL;

-- Customer documents indexes
CREATE INDEX idx_documents_customer_id ON customer_documents(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_type ON customer_documents(customer_id, document_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_status ON customer_documents(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_latest ON customer_documents(customer_id, document_type, is_latest) WHERE is_latest = true AND deleted_at IS NULL;
CREATE INDEX idx_documents_expiry ON customer_documents(expiry_date) WHERE expiry_date IS NOT NULL AND status = 'verified' AND deleted_at IS NULL;

-- KYC and approvals indexes
CREATE INDEX idx_kyc_customer_id ON kyc_verifications(customer_id);
CREATE INDEX idx_kyc_status ON kyc_verifications(verification_status, created_at DESC);
CREATE INDEX idx_approvals_customer_id ON customer_approvals(customer_id);
CREATE INDEX idx_approvals_status ON customer_approvals(approval_status, created_at DESC);

-- Audit log indexes
CREATE INDEX idx_audit_customer_id ON customer_audit_log(customer_id, changed_at DESC);
CREATE INDEX idx_audit_changed_by ON customer_audit_log(changed_by, changed_at DESC);

-- Address history indexes
CREATE INDEX idx_address_history_customer ON address_history(customer_id, valid_to DESC);

-- =====================================================
-- 6. TRIGGERS
-- =====================================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_customer_addresses_updated_at
    BEFORE UPDATE ON customer_addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_customer_documents_updated_at
    BEFORE UPDATE ON customer_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_customer_nominees_updated_at
    BEFORE UPDATE ON customer_nominees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_kyc_verifications_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_customer_approvals_updated_at
    BEFORE UPDATE ON customer_approvals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Search vector update trigger
CREATE OR REPLACE FUNCTION update_customer_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.first_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.middle_name, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.last_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.customer_code, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.mobile_primary, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.email, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.aadhaar_number, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.pan_number, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customer_search
    BEFORE INSERT OR UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_customer_search_vector();

-- Auto-generate customer code
CREATE OR REPLACE FUNCTION generate_customer_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.customer_code IS NULL OR NEW.customer_code = '' THEN
        NEW.customer_code := 'CUST' || LPAD(NEW.id::TEXT, 8, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_customer_code
    BEFORE INSERT ON customers
    FOR EACH ROW EXECUTE FUNCTION generate_customer_code();

-- Audit logging trigger
CREATE OR REPLACE FUNCTION log_customer_changes()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    changed_fields TEXT[];
BEGIN
    IF TG_OP = 'DELETE' THEN
        old_data := to_jsonb(OLD);
        INSERT INTO customer_audit_log (
            customer_id, table_name, action, old_values, 
            changed_by, changed_at
        ) VALUES (
            OLD.id, TG_TABLE_NAME, 'DELETE', old_data,
            OLD.deleted_by, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        
        SELECT ARRAY_AGG(key)
        INTO changed_fields
        FROM jsonb_each(old_data) AS old_kv
        WHERE old_kv.value IS DISTINCT FROM new_data->old_kv.key
        AND old_kv.key NOT IN ('updated_at', 'search_vector');
        
        IF changed_fields IS NOT NULL THEN
            INSERT INTO customer_audit_log (
                customer_id, table_name, action, old_values, new_values,
                changed_fields, changed_by, changed_at
            ) VALUES (
                NEW.id, TG_TABLE_NAME, 'UPDATE', old_data, new_data,
                changed_fields, NEW.updated_by, CURRENT_TIMESTAMP
            );
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        new_data := to_jsonb(NEW);
        INSERT INTO customer_audit_log (
            customer_id, table_name, action, new_values,
            changed_by, changed_at
        ) VALUES (
            NEW.id, TG_TABLE_NAME, 'INSERT', new_data,
            NEW.created_by, CURRENT_TIMESTAMP
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_customers
    AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW EXECUTE FUNCTION log_customer_changes();

-- Address history trigger
CREATE OR REPLACE FUNCTION track_address_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.deleted_at IS NULL THEN
        IF (OLD.address_line1 IS DISTINCT FROM NEW.address_line1 OR
            OLD.city IS DISTINCT FROM NEW.city OR
            OLD.state IS DISTINCT FROM NEW.state OR
            OLD.pincode IS DISTINCT FROM NEW.pincode) THEN
            
            INSERT INTO address_history (
                customer_id, address_id, address_type,
                address_line1, address_line2, city, state, pincode,
                valid_from, valid_to, changed_by, change_reason
            ) VALUES (
                OLD.customer_id, OLD.id, OLD.address_type,
                OLD.address_line1, OLD.address_line2, OLD.city, OLD.state, OLD.pincode,
                OLD.valid_from, CURRENT_DATE - INTERVAL '1 day',
                NEW.updated_by, 'Address Updated'
            );
            
            NEW.valid_from := CURRENT_DATE;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_track_address_history
    BEFORE UPDATE ON customer_addresses
    FOR EACH ROW EXECUTE FUNCTION track_address_changes();

-- Document versioning trigger
CREATE OR REPLACE FUNCTION manage_document_versions()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.parent_document_id IS NOT NULL THEN
        UPDATE customer_documents 
        SET is_latest = false,
            replaced_at = CURRENT_TIMESTAMP,
            replaced_by = NEW.created_by
        WHERE id = NEW.parent_document_id;
        
        SELECT COALESCE(MAX(version), 0) + 1
        INTO NEW.version
        FROM customer_documents
        WHERE customer_id = NEW.customer_id 
        AND document_type = NEW.document_type;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_manage_doc_versions
    BEFORE INSERT ON customer_documents
    FOR EACH ROW EXECUTE FUNCTION manage_document_versions();

-- =====================================================
-- 7. VIEWS
-- =====================================================

-- Active customers
CREATE VIEW vw_active_customers AS
SELECT 
    c.id,
    c.customer_code,
    c.first_name || ' ' || COALESCE(c.middle_name || ' ', '') || c.last_name AS full_name,
    c.date_of_birth,
    EXTRACT(YEAR FROM AGE(c.date_of_birth))::INTEGER AS age,
    c.gender,
    c.mobile_primary,
    c.email,
    c.status,
    c.kyc_status,
    c.credit_score,
    c.risk_category,
    c.monthly_income,
    c.employment_type,
    c.created_at,
    c.onboarded_at
FROM customers c
WHERE c.deleted_at IS NULL 
AND c.is_active = true
AND c.status = 'active';

-- Pending KYC customers
CREATE VIEW vw_pending_kyc_customers AS
SELECT 
    c.id,
    c.customer_code,
    c.first_name || ' ' || c.last_name AS full_name,
    c.mobile_primary,
    c.kyc_status,
    c.created_at,
    kv.verification_status,
    kv.aadhaar_verified,
    kv.pan_verified,
    kv.address_verified,
    kv.photo_verified,
    kv.reviewed_by,
    kv.reviewed_at
FROM customers c
LEFT JOIN kyc_verifications kv ON c.id = kv.customer_id
WHERE c.deleted_at IS NULL
AND c.kyc_status IN ('submitted', 'under_review')
ORDER BY c.created_at ASC;

-- Customer complete profile
CREATE VIEW vw_customer_complete_profile AS
SELECT 
    c.*,
    pa.address_line1 AS primary_address,
    pa.city AS primary_city,
    pa.state AS primary_state,
    pa.pincode AS primary_pincode,
    (SELECT COUNT(*) FROM customer_documents WHERE customer_id = c.id AND deleted_at IS NULL AND is_latest = true) AS total_documents,
    (SELECT COUNT(*) FROM customer_documents WHERE customer_id = c.id AND status = 'verified' AND deleted_at IS NULL AND is_latest = true) AS verified_documents,
    (SELECT COUNT(*) FROM customer_nominees WHERE customer_id = c.id AND deleted_at IS NULL) AS total_nominees
FROM customers c
LEFT JOIN customer_addresses pa ON c.id = pa.customer_id 
    AND pa.is_primary = true 
    AND pa.address_type = 'permanent'
    AND pa.deleted_at IS NULL
WHERE c.deleted_at IS NULL;

-- Expiring documents
CREATE VIEW vw_expiring_documents AS
SELECT 
    c.id AS customer_id,
    c.customer_code,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.mobile_primary,
    cd.id AS document_id,
    cd.document_type,
    cd.document_number,
    cd.expiry_date,
    (cd.expiry_date - CURRENT_DATE) AS days_to_expiry
FROM customers c
INNER JOIN customer_documents cd ON c.id = cd.customer_id
WHERE c.deleted_at IS NULL
AND cd.deleted_at IS NULL
AND cd.is_latest = true
AND cd.status = 'verified'
AND cd.expiry_date IS NOT NULL
AND cd.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days'
ORDER BY cd.expiry_date ASC;

-- =====================================================
-- 8. FUNCTIONS
-- =====================================================

-- Calculate KYC completion
CREATE OR REPLACE FUNCTION calculate_kyc_completion(p_customer_id BIGINT)
RETURNS DECIMAL AS $$
DECLARE
    total_required INTEGER := 5;
    documents_uploaded INTEGER;
    completion_percentage DECIMAL;
BEGIN
    SELECT COUNT(DISTINCT document_type)
    INTO documents_uploaded
    FROM customer_documents
    WHERE customer_id = p_customer_id
    AND document_type IN ('aadhaar_front', 'pan_card', 'address_proof', 'photo', 'signature')
    AND is_latest = true
    AND deleted_at IS NULL;
    
    completion_percentage := (documents_uploaded::DECIMAL / total_required) * 100;
    
    RETURN ROUND(completion_percentage, 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- Search customers
CREATE OR REPLACE FUNCTION search_customers(search_term TEXT)
RETURNS TABLE (
    id BIGINT,
    customer_code VARCHAR,
    full_name TEXT,
    mobile_primary VARCHAR,
    email VARCHAR,
    status customer_status,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.customer_code,
        c.first_name || ' ' || COALESCE(c.middle_name || ' ', '') || c.last_name,
        c.mobile_primary,
        c.email,
        c.status,
        ts_rank(c.search_vector, plainto_tsquery('english', search_term)) AS rank
    FROM customers c
    WHERE c.deleted_at IS NULL
    AND (
        c.search_vector @@ plainto_tsquery('english', search_term)
        OR c.first_name ILIKE '%' || search_term || '%'
        OR c.last_name ILIKE '%' || search_term || '%'
        OR c.customer_code ILIKE '%' || search_term || '%'
        OR c.mobile_primary ILIKE '%' || search_term || '%'
        OR c.email ILIKE '%' || search_term || '%'
    )
    ORDER BY rank DESC, c.created_at DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE;

-- Get customer summary
CREATE OR REPLACE FUNCTION get_customer_summary(p_customer_id BIGINT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'customer_info', (
            SELECT json_build_object(
                'id', id,
                'customer_code', customer_code,
                'full_name', first_name || ' ' || last_name,
                'mobile', mobile_primary,
                'email', email,
                'age', EXTRACT(YEAR FROM AGE(date_of_birth)),
                'status', status,
                'kyc_status', kyc_status
            )
            FROM customers WHERE id = p_customer_id AND deleted_at IS NULL
        ),
        'addresses', (
            SELECT json_agg(json_build_object(
                'type', address_type,
                'address', address_line1 || ', ' || city || ', ' || state,
                'pincode', pincode,
                'is_primary', is_primary
            ))
            FROM customer_addresses 
            WHERE customer_id = p_customer_id AND deleted_at IS NULL
        ),
        'documents', (
            SELECT json_agg(json_build_object(
                'type', document_type,
                'status', status,
                'expiry_date', expiry_date
            ))
            FROM customer_documents 
            WHERE customer_id = p_customer_id 
            AND is_latest = true 
            AND deleted_at IS NULL
        ),
        'kyc_completion', calculate_kyc_completion(p_customer_id)
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 9. STORED PROCEDURES
-- =====================================================

-- Soft delete customer
CREATE OR REPLACE PROCEDURE soft_delete_customer(
    p_customer_id BIGINT,
    p_deleted_by BIGINT,
    p_reason TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE customers
    SET deleted_at = CURRENT_TIMESTAMP,
        deleted_by = p_deleted_by,
        is_active = false
    WHERE id = p_customer_id AND deleted_at IS NULL;
    
    INSERT INTO customer_audit_log (
        customer_id, table_name, action, 
        changed_by, reason
    ) VALUES (
        p_customer_id, 'customers', 'SOFT_DELETE',
        p_deleted_by, p_reason
    );
END;
$$;

-- Approve KYC
CREATE OR REPLACE PROCEDURE approve_customer_kyc(
    p_customer_id BIGINT,
    p_approved_by BIGINT,
    p_comments TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE kyc_verifications
    SET verification_status = 'approved',
        reviewed_by = p_approved_by,
        reviewed_at = CURRENT_TIMESTAMP,
        reviewer_comments = p_comments,
        completed_at = CURRENT_TIMESTAMP
    WHERE customer_id = p_customer_id
    AND verification_status = 'pending';
    
    UPDATE customers
    SET kyc_status = 'approved',
        status = 'active',
        is_verified = true,
        verified_by = p_approved_by,
        verified_at = CURRENT_TIMESTAMP,
        updated_by = p_approved_by
    WHERE id = p_customer_id;
END;
$$;

-- Reject KYC
CREATE OR REPLACE PROCEDURE reject_customer_kyc(
    p_customer_id BIGINT,
    p_rejected_by BIGINT,
    p_reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE kyc_verifications
    SET verification_status = 'rejected',
        reviewed_by = p_rejected_by,
        reviewed_at = CURRENT_TIMESTAMP,
        rejection_reason = p_reason,
        completed_at = CURRENT_TIMESTAMP
    WHERE customer_id = p_customer_id
    AND verification_status = 'pending';
    
    UPDATE customers
    SET kyc_status = 'rejected',
        status = 'pending_verification',
        updated_by = p_rejected_by
    WHERE id = p_customer_id;
END;
$$;

-- =====================================================
-- 10. SAMPLE DATA
-- =====================================================

-- Insert sample customers
INSERT INTO customers (
    first_name, middle_name, last_name, date_of_birth, gender, marital_status,
    mobile_primary, email, occupation, employment_type, monthly_income,
    aadhaar_number, pan_number, status, kyc_status, created_by
) VALUES 
    ('Rajesh', 'Kumar', 'Sharma', '1985-05-15', 'male', 'married',
     '9876543210', 'rajesh.sharma@example.com', 'Small Business Owner', 'self_employed', 35000.00,
     '123456789012', 'ABCDE1234F', 'active', 'approved', 1),
    
    ('Priya', NULL, 'Patel', '1990-08-22', 'female', 'single',
     '9876543211', 'priya.patel@example.com', 'Tailor', 'self_employed', 18000.00,
     '234567890123', 'BCDEF2345G', 'active', 'approved', 1),
    
    ('Amit', 'Singh', 'Verma', '1988-03-10', 'male', 'married',
     '9876543212', 'amit.verma@example.com', 'Daily Wage Worker', 'daily_wage', 12000.00,
     '345678901234', 'CDEFG3456H', 'kyc_submitted', 'under_review', 1),
    
    ('Sunita', NULL, 'Devi', '1992-11-30', 'female', 'married',
     '9876543213', NULL, 'Vegetable Vendor', 'self_employed', 15000.00,
     '456789012345', 'DEFGH4567I', 'pending_verification', 'in_progress', 2),
    
    ('Ramesh', 'Chandra', 'Gupta', '1980-07-18', 'male', 'married',
     '9876543214', 'ramesh.gupta@example.com', 'Auto Driver', 'self_employed', 22000.00,
     '567890123456', 'EFGHI5678J', 'active', 'approved', 2);

-- Insert sample addresses
INSERT INTO customer_addresses (
    customer_id, address_type, address_line1, address_line2, landmark,
    city, district, state, pincode, is_primary, is_verified, created_by
) VALUES 
    (1, 'permanent', 'House No. 42, Sector 15', 'Near City Mall', 'Opposite Bank',
     'Mumbai', 'Mumbai Suburban', 'Maharashtra', '400001', true, true, 1),
    
    (1, 'current', 'Flat 301, Sunshine Apartments', 'MG Road', 'Near Metro Station',
     'Mumbai', 'Mumbai Suburban', 'Maharashtra', '400002', false, true, 1),
    
    (2, 'permanent', 'Plot No. 15, Gandhi Nagar', 'Behind School', 'Near Temple',
     'Ahmedabad', 'Ahmedabad', 'Gujarat', '380001', true, true, 1),
    
    (3, 'permanent', '23/A, Ram Nagar Colony', 'Main Road', 'Near Post Office',
     'Lucknow', 'Lucknow', 'Uttar Pradesh', '226001', true, false, 1),
    
    (4, 'permanent', 'Vill. Rampur, Post: Keshopur', NULL, 'Near Panchayat',
     'Patna', 'Patna', 'Bihar', '800001', true, false, 2),
    
    (5, 'permanent', 'Shop No. 7, Market Complex', 'Station Road', 'Near Bus Stand',
     'Jaipur', 'Jaipur', 'Rajasthan', '302001', true, true, 2);

-- Insert sample documents
INSERT INTO customer_documents (
    customer_id, document_type, document_number, document_name,
    file_url, file_type, file_size_kb, status, is_verified,
    issued_date, expiry_date, created_by
) VALUES 
    (1, 'aadhaar_front', '123456789012', 'Rajesh_Aadhaar_Front.jpg',
     's3://microfinance-docs/customers/1/aadhaar_front_v1.jpg', 'jpg', 245, 'verified', true,
     '2015-01-15', NULL, 1),
    
    (1, 'pan_card', 'ABCDE1234F', 'Rajesh_PAN.pdf',
     's3://microfinance-docs/customers/1/pan_v1.pdf', 'pdf', 180, 'verified', true,
     '2010-05-20', NULL, 1),
    
    (1, 'photo', NULL, 'Rajesh_Photo.jpg',
     's3://microfinance-docs/customers/1/photo_v1.jpg', 'jpg', 150, 'verified', true,
     NULL, NULL, 1),
    
    (2, 'aadhaar_front', '234567890123', 'Priya_Aadhaar_Front.jpg',
     's3://microfinance-docs/customers/2/aadhaar_front_v1.jpg', 'jpg', 230, 'verified', true,
     '2016-03-10', NULL, 1),
    
    (2, 'pan_card', 'BCDEF2345G', 'Priya_PAN.pdf',
     's3://microfinance-docs/customers/2/pan_v1.pdf', 'pdf', 175, 'verified', true,
     '2012-08-15', NULL, 1),
    
    (3, 'aadhaar_front', '345678901234', 'Amit_Aadhaar_Front.jpg',
     's3://microfinance-docs/customers/3/aadhaar_front_v1.jpg', 'jpg', 255, 'under_verification', false,
     '2017-06-20', NULL, 1),
    
    (4, 'aadhaar_front', '456789012345', 'Sunita_Aadhaar_Front.jpg',
     's3://microfinance-docs/customers/4/aadhaar_front_v1.jpg', 'jpg', 240, 'uploaded', false,
     '2018-02-14', NULL, 2);

-- Insert sample KYC verifications
INSERT INTO kyc_verifications (
    customer_id, verification_type, verification_status,
    aadhaar_verified, pan_verified, address_verified, photo_verified
) VALUES 
    (1, 'manual', 'approved', true, true, true, true),
    (2, 'manual', 'approved', true, true, true, true),
    (3, 'manual', 'pending', true, true, false, false),
    (4, 'manual', 'pending', false, false, false, false);

-- Insert sample nominees
INSERT INTO customer_nominees (
    customer_id, nominee_name, relationship, date_of_birth,
    mobile_number, share_percentage, is_primary, created_by
) VALUES 
    (1, 'Sunita Sharma', 'Wife', '1987-09-20', '9876543220', 100.00, true, 1),
    (2, 'Rajesh Patel', 'Father', '1960-04-15', '9876543221', 100.00, true, 1),
    (3, 'Anita Verma', 'Wife', '1990-12-05', '9876543222', 50.00, true, 1),
    (3, 'Vikram Verma', 'Son', '2015-03-10', NULL, 50.00, false, 1);

-- =====================================================
-- 11. FINAL OPTIMIZATION
-- =====================================================

-- Analyze tables for query optimization
ANALYZE customers;
ANALYZE customer_addresses;
ANALYZE customer_documents;
ANALYZE customer_nominees;
ANALYZE kyc_verifications;
ANALYZE customer_approvals;
ANALYZE address_history;

-- =====================================================
-- SCHEMA CREATION COMPLETE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================================';
    RAISE NOTICE 'Customer Management Schema Created Successfully!';
    RAISE NOTICE '========================================================';
    RAISE NOTICE 'PostgreSQL Version: 17';
    RAISE NOTICE 'Tables Created: 8';
    RAISE NOTICE 'Views Created: 4';
    RAISE NOTICE 'Functions Created: 3';
    RAISE NOTICE 'Procedures Created: 3';
    RAISE NOTICE 'Triggers Created: 8';
    RAISE NOTICE 'Indexes Created: 30+';
    RAISE NOTICE 'Sample Customers: 5';
    RAISE NOTICE '========================================================';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Test with: SELECT * FROM vw_active_customers;';
    RAISE NOTICE '2. Search: SELECT * FROM search_customers(''rajesh'');';
    RAISE NOTICE '3. Get Summary: SELECT get_customer_summary(1);';
    RAISE NOTICE '========================================================';
END
$$;