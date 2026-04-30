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
