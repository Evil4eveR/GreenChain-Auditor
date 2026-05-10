-- Enable UUID extension (Required for your suppliers table)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table (Stores user information, including email, password hash, role, and timestamps for tracking when users are created)
CREATE TABLE If NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR (255),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'Auditor',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Suppliers Table (References users for tracking who created/updated the supplier, and includes all necessary fields for the supplier data)
CREATE TABLE If NOT EXISTS suppliers ( 
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
    registration_number VARCHAR(100) UNIQUE NOT NULL, 
    legal_name VARCHAR(255) NOT NULL, 
    country_code CHAR(2) NOT NULL,
    country VARCHAR(100) NOT NULL,
    industry_sector VARCHAR(100), 
    co2_emissions_annual NUMERIC(12, 2), 
    social_compliance_score NUMERIC(3, 2),
    status VARCHAR(20) DEFAULT 'pending',
    contact_name VARCHAR(150),
    contact_email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP 
);

-- 3. Imports Table (References users for tracking who did the import, and stores raw data for processing)
CREATE TABLE If NOT EXISTS imports (
    id BIGSERIAL PRIMARY KEY, --BIGSERIAL handles itself
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    raw_data JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Audit Logs Table (Tracks all changes to suppliers, including who made the change and what was changed)
CREATE TABLE If NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    supplier_id UUID REFERENCES suppliers(id)
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Added user_id to see who did the action!
    action VARCHAR(255) NOT NULL,
    previous_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);