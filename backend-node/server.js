// laod environment variables from .env file
require('dotenv').config({ path: '../.env'});

// Import the libraries we installed
const express = require('express');     // Web framework
const { Pool } = require('pg');          // Postgres connection pool
const cors = require('cors');              // Allow frontend to connection

const app = express();

app.use(cors());

app.use(express.json());

const pool = new Pool({
    host: 'localhost',
    port: parseInt(process.env.POSTGRES_PORT) || 5432,
    database: process.env.POSTGRES_DB,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
});

pool.connect()
    .then(() => console.log('✅ Connected to PostgreSQL'))
    .catch(err =>console.error('❌ Database connection failed:', 
err.message));

//ROUTES

app.get('/', (req, res) => {
    res.json({
        message : 'GreenChain API is running',
        timestamp: new Date().toISOString()
    });
});

app.get('/suppliers', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM suppliers ORDER BY created_at DESC');
        res.json({
            success: true,
            count: result.rowCount,
            data: result.rows
        });
    } catch (err) {
        console.error('Error fetching suppliers:', err);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch suppliers'
        });
    }
});
app.post('/suppliers', async (req, res) => {
    try {
        // Get data from the request body
        const {
            registration_number,
            legal_name,
            country_code,
            country,
            industry_sector,
            co2_emissions_annual,
            social_compliance_score,
            contact_name,
            contact_email
        } = req.body;
        
        // Basic validation
        if (!registration_number || !legal_name || !country_code) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields: registration_number, legal_name, country_code'
            });
        }
        
        // Insert into database
        const result = await pool.query(
            `INSERT INTO suppliers 
             (registration_number, legal_name, country_code, country, industry_sector, 
              co2_emissions_annual, social_compliance_score, status, contact_name, contact_email)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
             RETURNING *`,
            [
                registration_number,
                legal_name,
                country_code,
                country || null,
                industry_sector || null,
                co2_emissions_annual || null,
                social_compliance_score || null,
                'active',
                contact_name || null,
                contact_email || null
            ]
        );
        
        // Return the created supplier
        res.status(201).json({
            success: true,
            message: 'Supplier created successfully',
            data: result.rows[0]
        });
    } catch (err) {
        console.error('Error creating supplier:', err);
        
        // Check for duplicate registration number
        if (err.code === '23505') {
            return res.status(409).json({
                success: false,
                error: 'Supplier with this registration number already exists'
            });
        }
        
        res.status(500).json({
            success: false,
            error: 'Failed to create supplier'
        });
    }
});

// ============================================
// START THE SERVER
// ============================================

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📋 Available endpoints:`);
    console.log(`   GET  http://localhost:${PORT}/`);
    console.log(`   GET  http://localhost:${PORT}/suppliers`);
    console.log(`   GET  http://localhost:${PORT}/suppliers/:id`);
    console.log(`   POST http://localhost:${PORT}/suppliers`);
});