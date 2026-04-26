-- 1. Organizations
CREATE TABLE Organizations (
    org_id SERIAL PRIMARY KEY,
    org_name VARCHAR(150) NOT NULL,
    industry VARCHAR(100),
    country VARCHAR(80),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Teams
CREATE TABLE Teams (
    team_id SERIAL PRIMARY KEY,
    org_id INTEGER NOT NULL,
    team_name VARCHAR(150) NOT NULL,
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (org_id)
        REFERENCES Organizations(org_id)
        ON DELETE CASCADE
);

-- 3. Users
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    team_id INTEGER,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'engineer',
    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (team_id)
        REFERENCES Teams(team_id)
        ON DELETE SET NULL
);

-- 4. LLM_Models
CREATE TABLE LLM_Models (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    provider VARCHAR(80) NOT NULL,
    version VARCHAR(50),
    input_cost_per_1k NUMERIC(10,6) DEFAULT 0,
    output_cost_per_1k NUMERIC(10,6) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- 5. Systems
CREATE TABLE Systems (
    system_id SERIAL PRIMARY KEY,
    org_id INTEGER NOT NULL,
    system_name VARCHAR(150) NOT NULL,
    system_type VARCHAR(80) NOT NULL,
    ip_address INET,
    os_version VARCHAR(100),
    is_internet_facing BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (org_id)
        REFERENCES Organizations(org_id)
        ON DELETE CASCADE
);

-- 6. API_Calls
CREATE TABLE API_Calls (
    call_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    model_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    latency_ms INTEGER,
    status_code INTEGER DEFAULT 200,
    called_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (user_id)
        REFERENCES Users(user_id)
        ON DELETE SET NULL,

    FOREIGN KEY (model_id)
        REFERENCES LLM_Models(model_id)
        ON DELETE RESTRICT,

    FOREIGN KEY (team_id)
        REFERENCES Teams(team_id)
        ON DELETE RESTRICT
);

-- 7. Cost_Records
CREATE TABLE Cost_Records (
    cost_id SERIAL PRIMARY KEY,
    call_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    input_cost_usd NUMERIC(12,6) DEFAULT 0,
    output_cost_usd NUMERIC(12,6) DEFAULT 0,
    total_cost_usd NUMERIC(12,6) DEFAULT 0,
    billing_period DATE NOT NULL,

    FOREIGN KEY (call_id)
        REFERENCES API_Calls(call_id)
        ON DELETE CASCADE,

    FOREIGN KEY (team_id)
        REFERENCES Teams(team_id)
        ON DELETE RESTRICT
);

-- 8. Vulnerabilities
CREATE TABLE Vulnerabilities (
    vuln_id SERIAL PRIMARY KEY,
    system_id INTEGER,
    model_id INTEGER,
    cve_id VARCHAR(20),
    severity VARCHAR(20) DEFAULT 'MEDIUM',
    description TEXT NOT NULL,
    reported_at TIMESTAMP DEFAULT NOW(),
    is_patched BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (system_id)
        REFERENCES Systems(system_id)
        ON DELETE SET NULL,

    FOREIGN KEY (model_id)
        REFERENCES LLM_Models(model_id)
        ON DELETE SET NULL
);

-- 9. Attack_Types
CREATE TABLE Attack_Types (
    attack_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    mitre_tactic VARCHAR(100),
    attack_category VARCHAR(80),
    description TEXT
);

-- 10. Incidents
CREATE TABLE Incidents (
    incident_id SERIAL PRIMARY KEY,
    org_id INTEGER NOT NULL,
    system_id INTEGER,
    actor_name VARCHAR(150),
    attack_type_id INTEGER NOT NULL,
    severity VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(30) DEFAULT 'OPEN',
    detected_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP,
    description TEXT,

    FOREIGN KEY (org_id)
        REFERENCES Organizations(org_id)
        ON DELETE RESTRICT,

    FOREIGN KEY (system_id)
        REFERENCES Systems(system_id)
        ON DELETE SET NULL,

    FOREIGN KEY (attack_type_id)
        REFERENCES Attack_Types(attack_type_id)
        ON DELETE RESTRICT
);

-- 11. Mitigation_Actions
CREATE TABLE Mitigation_Actions (
    action_id SERIAL PRIMARY KEY,
    incident_id INTEGER NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    performed_by INTEGER,
    performed_at TIMESTAMP DEFAULT NOW(),
    notes TEXT,

    FOREIGN KEY (incident_id)
        REFERENCES Incidents(incident_id)
        ON DELETE CASCADE,

    FOREIGN KEY (performed_by)
        REFERENCES Users(user_id)
        ON DELETE SET NULL
);
