# GreenChain-Auditor
A RegTech platform for supplier sustainability scoring, LkSG compliance, and supply-chain risk intelligence. 

# Running PostgreSQL with Docker Compose

This guide provides instructions for setting up and running a **PostgreSQL** container using **Docker Compose**. It also includes steps for troubleshooting common issues like DNS resolution errors.

## Prerequisites

Before you begin, make sure you have the following installed:

- Docker
- Docker Compose

## Step-by-Step Guide

### 1. **Verify Docker is Installed**
To check if Docker is installed and running, use the following command:

```bash
sudo docker ps
```
### 2 Starting PostgreSQL with Docker Compose

#### 3 incase(DNS Issue While Running Docker Compose)

After running docker-compose up -d, you might encounter a DNS resolution error. The error message may look like this:

This happens because Docker is trying to resolve DNS requests using the local DNS server (on [::1]:53), but it's unable to do so.

### 4. Fixing DNS Resolution in Docker

To resolve this issue, we will configure Docker to use Google’s public DNS servers.

Edit Docker's daemon configuration by opening the daemon.json file:

```sudo nano /etc/docker/daemon.json```

Add Google DNS servers (8.8.8.8 and 8.8.4.4) as follows:

```
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```
Save the file (press Ctrl+X, then Y to confirm, and Enter to save).

Restart Docker to apply the new DNS settings:

```sudo systemctl restart docker```

### 5. Verify the PostgreSQL Container is Running

Once Docker is restarted, you can verify that your PostgreSQL container is up and running with the following command:

```sudo docker ps```

The container should now be running, and you can interact with it as needed.

### 6. Access Logs for Debugging

If you need to check the logs for your PostgreSQL container, use the following command:

```sudo docker logs greenchain_postgres```

This will display the logs of the greenchain_postgres container.

### 7. Pulling the Image Manually

If Docker is still unable to pull the image, you can manually test pulling the image using:

```sudo docker pull postgres:16-alpine```

If this works, it means the DNS issue is resolved.

# Database Overview

## 🏗️ Architectural Overview

The system utilizes PostgreSQL with a hybrid relational/document approach. It consists of 4 core tables designed to separate raw user input from verified corporate data.

### Core Tables

| Table        | Purpose                                               | ID Type    | Strategy                          |
|--------------|-------------------------------------------------------|------------|-----------------------------------|
| `users`      | Identity & RBAC                                      | UUID       | Secure, unguessable identifiers.  |
| `suppliers`  | Verified "Golden" Records                             | UUID       | Privacy-focused public records.   |
| `imports`    | Raw Data Ingestion (Inbox)                            | BIGSERIAL  | Performance-optimized sequential logs. |
| `audit_logs` | Compliance Paper Trail                                | BIGSERIAL  | Fast-insert append-only history.  |

## 📊 Data Models & Logic

### 1. `users`  
Manages application access.  
- **Security**: Uses `gen_random_uuid()` for IDs to prevent account enumeration.  
- **Roles**: Implements basic Role-Based Access Control (RBAC) via the `role` column (e.g., Auditor, Manager).

### 2. `suppliers`  
The finalized output of the Python processing engine.  
- **Data Integrity**: `registration_number` is strictly unique.  
- **ESG Metrics**: Stores `co2_emissions_annual` and `social_compliance_score` for risk analysis.

### 3. `imports`  
The "landing zone" for external data.  
- **JSONB Ingestion**: Stores the raw JSON payload exactly as received. This allows the Python service to re-process data if business logic changes without asking the user for a re-upload.  
- **Ownership**: Linked to users via a Foreign Key to track data provenance.

### 4. `audit_logs`  
A legally required tracking mechanism.  
- **Traceability**: Every change made by the Python engine or a User is logged here.  
- **Resilience**: Uses `ON DELETE SET NULL` for references, ensuring that even if a user is deleted, the historical record of the action remains for legal compliance.

## 🛠️ Implementation Details

### Extensions Used
- **`uuid-ossp`**: For generating version 4 UUIDs.

### Key Performance Decisions
- **Indexing**: B-Tree indexes are applied to `registration_number` and `email` for \( O(\log n) \) lookup speeds.
- **Foreign Keys**: Strictly enforced referential integrity to prevent orphaned data records.
- **Timestamps**: All tables include `timestamp with time zone` to ensure accurate global synchronization, vital for international supply chains.

## 🐘 PostgreSQL 

changing column name 

```ALTER TABLE suppliers DROP COLUMN counttry;```

rename the column counttry to country

```ALTER TABLE suppliers RENAME COLUMN counttry TO country;```

to create tables run this command
```sudo docker exec -i {container_name} psql -U {user_name} -d {database_name} < database/schema.sql ```
Altirnative way
```psql -h localhost -p {port} -U {user_name} -d {database_name} -f database/schema.sql```
## mirror.yml added

# GreenChain-Auditor — Backend API Setup Guide

> **Status:** Backend Node.js server running with PostgreSQL connection  
> **Location:** `backend-node/`  
> **Port:** `3001` (default)

---

## Table of Contents

1. [What We Built](#what-we-built)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
   - Step 1: Initialize Node.js Project
   - Step 2: Install Dependencies
   - Step 3: Create Server File
   - Step 4: Configure Scripts
   - Step 5: Start the Server
   - Step 6: Test the API
5. [API Endpoints Reference](#api-endpoints-reference)
6. [Understanding the Code](#understanding-the-code)
   - The Request/Response Flow
   - Key Concepts
   - Error Handling
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## What We Built

A REST API server that:

- Connects to our PostgreSQL database (running in Docker)
- Handles HTTP requests from the frontend (or any client)
- Returns supplier data as JSON
- Creates new suppliers with validation
- Provides clear error messages when things go wrong

**Architecture Overview:**

```
┌─────────────┐      HTTP Request       ┌──────────────┐      SQL Query       ┌─────────────┐
│   Browser   │ ──────────────────────> │  Node.js API │ ───────────────────> │  PostgreSQL │
│  (Frontend) │  GET /suppliers         │   (Port 3001)│  SELECT * FROM...   │   (Docker)  │
│             │ <────────────────────── │              │ <─────────────────── │             │
└─────────────┘      JSON Response      └──────────────┘      Result Rows      └─────────────┘
```

---

## Project Structure

```
backend-node/
├── node_modules/          # Installed libraries (auto-generated)
├── server.js              # Main API server file
├── package.json           # Project config & dependencies
├── package-lock.json      # Locked dependency versions
└── .env (loaded from ../) # Environment variables
```

---

## Prerequisites

Before starting, ensure you have:

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| Docker & Docker Compose | Latest | `docker --version` |
| PostgreSQL container | Running | `docker ps` |

**Your `.env` file (in repo root) must contain:**

```bash
POSTGRES_DB=databas_ename
POSTGRES_USER=user_name
POSTGRES_PASSWORD=your_password
POSTGRES_PORT=5432
```

---

## Step-by-Step Setup

### Step 1: Initialize Node.js Project

```bash
cd backend-node
npm init -y
```

**What this does:** Creates `package.json` — the "identity card" of your Node.js project. It tracks name, version, dependencies, and scripts.

**Generated `package.json`:**

```json
{
  "name": "backend-node",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

---

### Step 2: Install Dependencies

```bash
npm install express pg dotenv cors
npm install --save-dev nodemon
```

**Installed Packages:**

| Package | Type | Purpose |
|---------|------|---------|
| `express` | Production | Web framework — handles HTTP requests and routing |
| `pg` | Production | PostgreSQL client — connects to our database |
| `dotenv` | Production | Loads environment variables from `.env` file |
| `cors` | Production | Allows frontend (different port) to communicate with backend |
| `nodemon` | Development | Auto-restarts server when code changes are saved |

**What happens:**
- Creates `node_modules/` folder (contains all library code)
- Creates `package-lock.json` (locks exact versions for consistency)
- Updates `package.json` with dependency list

---

### Step 3: Create Server File

Create `backend-node/server.js`:
---

### Step 4: Configure npm Scripts

Update `backend-node/package.json`:

```json
{
  "name": "backend-node",
  "version": "1.0.0",
  "description": "GreenChain Auditor API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "pg": "^8.11.5"
  },
  "devDependencies": {
    "nodemon": "^3.1.0"
  }
}
```

**Scripts explained:**

| Script | Command | When to Use |
|--------|---------|-------------|
| `npm start` | `node server.js` | Production — runs once |
| `npm run dev` | `nodemon server.js` | Development — auto-restarts on file changes |

---

### Step 5: Start the Server

**Prerequisite:** PostgreSQL container must be running:

```bash
# From repo root
docker-compose ps
# Expected: greenchain_postgres ... Up
```

**Start the API server:**

```bash
cd backend-node
npm run dev
```

**Expected output:**

```
[nodemon] starting `node server.js`
🚀 Server running on http://localhost:3001
📋 Available endpoints:
   GET  http://localhost:3001/
   GET  http://localhost:3001/suppliers
   GET  http://localhost:3001/suppliers/:id
   POST http://localhost:3001/suppliers
✅ Connected to PostgreSQL
```

---

### Step 6: Test the API

#### Test 1: Health Check

```bash
curl http://localhost:3001/
```

**Expected response:**

```json
{
  "message": "GreenChain API is running!",
  "timestamp": "2024-05-10T14:30:00.000Z"
}
```

---

#### Test 2: List All Suppliers

```bash
curl http://localhost:3001/suppliers
```

**Expected response:**

```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "id": "....",
      "registration_number": "...",
      "legal_name": "...",
      "country_code": "..",
      "country": "...",
      "industry_sector": ".....",
      "co2_emissions_annual": ".......",
      "social_compliance_score": ".......",
      "status": "active",
      "created_at": "........"
    }
  ]
}
```

---

#### Test 3: Get Single Supplier

```bash
curl http://localhost:3001/suppliers/{suppliers_id}
```

**Expected response:**

```json
{
  "success": true,
  "data": {
    "id": "sup_id",
    "registration_number": ".....",
    "legal_name": ".....",
    ...
  }
}
```

---

#### Test 4: Create New Supplier

```bash
curl -X POST http://localhost:3001/suppliers \\
  -H "Content-Type: application/json" \\
  -d '{
    "registration_number": "numberExample",
    "legal_name": "legal_name SA",
    "country_code": "Cr",
    "country": "Country",
    "industry_sector": "EnergyExample",
    "co2_emissions_annual": 3200000.50,
    "social_compliance_score": 7.00,
    "contact_name": "name name2",
    "contact_email": "example@test.com"
  }'
```

**Expected response:**

```json
{
  "success": true,
  "message": "Supplier created successfully",
  ...
  }
}
```

---

## API Endpoints Reference

| Method | Endpoint | Description | Status Codes |
|--------|----------|-------------|--------------|
| `GET` | `/` | Health check | `200` |
| `GET` | `/suppliers` | List all suppliers | `200`, `500` |
| `GET` | `/suppliers/:id` | Get supplier by UUID | `200`, `404`, `500` |
| `POST` | `/suppliers` | Create new supplier | `201`, `400`, `409`, `500` |

**HTTP Status Codes:**

| Code | Meaning | When It Happens |
|------|---------|-----------------|
| `200` | OK | Request succeeded |
| `201` | Created | New resource created successfully |
| `400` | Bad Request | Missing required fields |
| `404` | Not Found | Supplier ID does not exist |
| `409` | Conflict | Duplicate registration_number |
| `500` | Internal Server Error | Database or unexpected error |

---

## Understanding the Code

### The Request/Response Flow

```
┌─────────────┐                    ┌──────────────┐                    ┌─────────────┐
│   Client    │  1. HTTP Request   │    Express   │   2. SQL Query     │  PostgreSQL │
│  (Browser   │ ────────────────>  │   Server     │  ───────────────>  │   (Docker)  │
│   or curl)  │  GET /suppliers    │   (Node.js)  │  SELECT * FROM...  │             │
│             │                    │              │                    │             │
│             │  4. JSON Response  │              │   3. Result Rows   │             │
│             │ <────────────────  │              │ <────────────────  │             │
└─────────────┘  {data: [...]}     └──────────────┘                    └─────────────┘
```

### Key Concepts

| Concept | Explanation | Example in Code |
|---------|-------------|-----------------|
| **Express `app`** | The server application instance | `const app = express();` |
| **Route** | URL pattern + HTTP method | `app.get('/suppliers', ...)` |
| **Handler** | Function executed when route matches | `async (req, res) => {...}` |
| **`req` (Request)** | Object containing client data | `req.params.id`, `req.body` |
| **`res` (Response)** | Object used to send data back | `res.json()`, `res.status()` |
| **Middleware** | Functions that process requests | `app.use(cors())`, `app.use(express.json())` |
| **`async/await`** | Handle asynchronous operations | `await pool.query(...)` |
| **Connection Pool** | Reusable database connections | `new Pool({...})` |
| **Parameterized Query** | Prevents SQL injection attacks | `$1, $2` with array values |

### Error Handling

The API handles three types of errors:

1. **Validation Errors (400)** — Client sent incomplete data
   ```javascript
   if (!registration_number || !legal_name || !country_code) {
       return res.status(400).json({ error: 'Missing required fields' });
   }
   ```

2. **Not Found Errors (404)** — Requested resource doesn't exist
   ```javascript
   if (result.rows.length === 0) {
       return res.status(404).json({ error: 'Supplier not found' });
   }
   ```

3. **Database Errors (409/500)** — Unique constraint violations or unexpected failures
   ```javascript
   if (err.code === '23505') {  // Postgres unique violation code
       return res.status(409).json({ error: 'Already exists' });
   }
   ```

---

## Troubleshooting

### Problem: `Error: connect ECONNREFUSED 127.0.0.1:5432`

**Cause:** PostgreSQL container is not running.

**Fix:**
```bash
cd ..  # Go to repo root
docker-compose up -d
docker ps  # Verify greenchain_postgres is running
```

---

### Problem: `Cannot find module 'express'`

**Cause:** Dependencies not installed.

**Fix:**
```bash
cd backend-node
npm install
```

---

### Problem: `password authentication failed for user "greenchain"`

**Cause:** `.env` file missing or incorrect credentials.

**Fix:**
```bash
cat ../.env  # Verify file exists and has correct values
docker-compose down -v  # Remove old volume (WARNING: deletes data)
docker-compose up -d      # Recreate with new credentials
```

---

### Problem: Port 3001 already in use

**Cause:** Another process is using port 3001.

**Fix:**
```bash
# Find and kill process
lsof -ti:3001 | xargs kill -9
# Or use a different port
PORT=3002 npm run dev
```