CREATE TABLE suppliers ( 
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), 
registration_number VARCHAR(100) UNIQUE NOT NULL, 
legal_name VARCHAR(255) NOT NULL, 
country_code CHAR(2) NOT NULL,
counttry VARCHAR(100) NOT NULL,
industry_sector VARCHAR(100), -- Risk Data (The numbers Python will use) 
co2_emissions_annual NUMERIC(12, 2), 
social_compliance_score NUMERIC(3, 2),
status VARCHAR(20) DEFAULT 'pending',
contact_name VARCHAR(150),
contact_email VARCHAR(255),
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP 
);