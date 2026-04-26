
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

-- Insert organizations
INSERT INTO Organizations (org_name, industry, country)
SELECT 
    'Org_' || i,
    (ARRAY['FinTech', 'Healthcare', 'Education', 'Retail', 'Cybersecurity'])[1 + (random()*4)::int],
    (ARRAY['USA', 'Canada', 'UK', 'India'])[1 + (random()*3)::int]
FROM generate_series(1, 20) AS i;
SELECT COUNT(*) FROM Organizations;

INSERT INTO Teams (org_id, team_name, department)
SELECT 
    (random()*19 + 1)::int,  -- random org_id from 1–20
    'Team_' || i,
    (ARRAY['Engineering', 'Finance', 'SOC', 'ML', 'Analytics'])[1 + (random()*4)::int]
FROM generate_series(1, 100) AS i;
SELECT COUNT(*) FROM Teams;

INSERT INTO Users (team_id, username, email, role)
SELECT
    (random()*99 + 1)::int,
    'user_' || i,
    'user_' || i || '@secureai.com',
    (ARRAY['engineer', 'analyst', 'admin', 'soc_analyst'])[1 + (random()*3)::int]
FROM generate_series(1, 500) AS i;
SELECT COUNT(*) FROM Users;

INSERT INTO LLM_Models 
(model_name, provider, version, input_cost_per_1k, output_cost_per_1k, is_active)
VALUES
('gpt-4o', 'OpenAI', '2024-11-20', 0.005, 0.015, TRUE),
('gpt-4o-mini', 'OpenAI', '2024-07-18', 0.00015, 0.00060, TRUE),
('claude-3-opus', 'Anthropic', '2024-02-29', 0.015, 0.075, TRUE),
('claude-3-sonnet', 'Anthropic', '2024-02-29', 0.003, 0.015, TRUE),
('gemini-1.5-pro', 'Google', '2024-05-14', 0.0035, 0.0105, TRUE),
('gemini-1.5-flash', 'Google', '2024-05-14', 0.00035, 0.00105, TRUE),
('llama-3-70b', 'Meta', '2024-04-18', 0.0009, 0.0009, TRUE),
('mistral-large', 'Mistral', '2024-02-26', 0.004, 0.012, TRUE),
('command-r-plus', 'Cohere', '2024-04-04', 0.003, 0.015, TRUE),
('deepseek-chat', 'DeepSeek', '2025-01-01', 0.00014, 0.00028, TRUE);

SELECT COUNT(*) FROM LLM_Models;

INSERT INTO Systems 
(org_id, system_name, system_type, ip_address, os_version, is_internet_facing)
SELECT
    (random()*19 + 1)::int,
    'system_' || i,
    (ARRAY['server', 'endpoint', 'llm_middleware', 'saas', 'api_gateway'])[1 + (random()*4)::int],
    ('10.0.' || ((random()*255)::int) || '.' || ((random()*255)::int))::inet,
    (ARRAY['Ubuntu 22.04', 'Windows Server 2022', 'macOS 14', 'Amazon Linux 2'])[1 + (random()*3)::int],
    random() > 0.5
FROM generate_series(1, 150) AS i;
SELECT COUNT(*) FROM Systems;

INSERT INTO Attack_Types (type_name, mitre_tactic, attack_category, description)
VALUES
('Prompt Injection', 'Initial Access', 'AI-specific', 'Manipulates prompts to override intended LLM behavior.'),
('Jailbreak Attempt', 'Defense Evasion', 'AI-specific', 'Attempts to bypass model safety or policy restrictions.'),
('Data Exfiltration', 'Exfiltration', 'Network', 'Attempts to extract sensitive information.'),
('Ransomware', 'Impact', 'Endpoint', 'Encrypts data and demands payment.'),
('Credential Theft', 'Credential Access', 'Identity', 'Steals user credentials or API keys.'),
('SQL Injection', 'Initial Access', 'Application', 'Injects malicious SQL into input fields.'),
('Malicious API Automation', 'Execution', 'AI-specific', 'Automated abuse of API calls.'),
('DDoS Attack', 'Impact', 'Network', 'Overloads a system with traffic.');
SELECT COUNT(*) FROM Attack_Types;

INSERT INTO API_Calls
(user_id, model_id, team_id, input_tokens, output_tokens, latency_ms, status_code, called_at)
SELECT
    (random()*499 + 1)::int,
    (random()*9 + 1)::int,
    (random()*99 + 1)::int,
    (random()*5000 + 100)::int,
    (random()*3000 + 50)::int,
    (random()*2500 + 100)::int,
    (ARRAY[200, 200, 200, 200, 400, 401, 429, 500])[1 + (random()*7)::int],
    NOW() - ((random()*90)::int || ' days')::interval
FROM generate_series(1, 2500);
SELECT COUNT(*) FROM API_Calls;

INSERT INTO Cost_Records
(call_id, team_id, input_cost_usd, output_cost_usd, total_cost_usd, billing_period)
SELECT
    a.call_id,
    a.team_id,
    ROUND(((a.input_tokens / 1000.0) * m.input_cost_per_1k)::numeric, 6),
    ROUND(((a.output_tokens / 1000.0) * m.output_cost_per_1k)::numeric, 6),
    ROUND((((a.input_tokens / 1000.0) * m.input_cost_per_1k) +
           ((a.output_tokens / 1000.0) * m.output_cost_per_1k))::numeric, 6),
    DATE_TRUNC('month', a.called_at)::date
FROM API_Calls a
JOIN LLM_Models m ON a.model_id = m.model_id;
SELECT COUNT(*) FROM Cost_Records;

INSERT INTO Vulnerabilities
(system_id, model_id, cve_id, severity, description, reported_at, is_patched)
SELECT
    (random()*149 + 1)::int,
    (random()*9 + 1)::int,
    'CVE-2026-' || LPAD(i::text, 5, '0'),
    (ARRAY['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])[1 + (random()*3)::int],
    'Synthetic vulnerability affecting AI infrastructure component #' || i,
    NOW() - ((random()*120)::int || ' days')::interval,
    random() > 0.6
FROM generate_series(1, 250) AS i;
SELECT COUNT(*) FROM Vulnerabilities;

INSERT INTO Incidents
(org_id, system_id, actor_name, attack_type_id, severity, status, detected_at, resolved_at, description)
SELECT
    (random()*19 + 1)::int,
    (random()*149 + 1)::int,
    (ARRAY['Unknown', 'APT-Shadow', 'Botnet-X', 'Insider', 'ScriptKiddie'])[1 + (random()*4)::int],
    (random()*7 + 1)::int,
    (ARRAY['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])[1 + (random()*3)::int],
    (ARRAY['OPEN', 'INVESTIGATING', 'RESOLVED'])[1 + (random()*2)::int],
    NOW() - ((random()*90)::int || ' days')::interval,
    CASE 
        WHEN random() > 0.5 
        THEN NOW() - ((random()*30)::int || ' days')::interval 
        ELSE NULL 
    END,
    'Synthetic security incident #' || i
FROM generate_series(1, 150) AS i;
SELECT COUNT(*) FROM Incidents;

INSERT INTO Mitigation_Actions
(incident_id, action_type, performed_by, performed_at, notes)
SELECT
    (random()*149 + 1)::int,
    (ARRAY['patch', 'block_ip', 'revoke_key', 'quarantine', 'rate_limit'])[1 + (random()*4)::int],
    (random()*499 + 1)::int,
    NOW() - ((random()*60)::int || ' days')::interval,
    'Mitigation action completed for incident #' || i
FROM generate_series(1, 200) AS i;
SELECT COUNT(*) FROM Mitigation_Actions;

SELECT 
    (SELECT COUNT(*) FROM Organizations) +
    (SELECT COUNT(*) FROM Teams) +
    (SELECT COUNT(*) FROM Users) +
    (SELECT COUNT(*) FROM LLM_Models) +
    (SELECT COUNT(*) FROM Systems) +
    (SELECT COUNT(*) FROM Attack_Types) +
    (SELECT COUNT(*) FROM API_Calls) +
    (SELECT COUNT(*) FROM Cost_Records) +
    (SELECT COUNT(*) FROM Vulnerabilities) +
    (SELECT COUNT(*) FROM Incidents) +
    (SELECT COUNT(*) FROM Mitigation_Actions)
AS total_rows;

SELECT 
    t.team_name,
    SUM(c.total_cost_usd) AS total_spend
FROM Cost_Records c
JOIN Teams t ON c.team_id = t.team_id
GROUP BY t.team_name
ORDER BY total_spend DESC
LIMIT 10;

SELECT 
    u.username,
    COUNT(a.call_id) AS total_calls
FROM API_Calls a
JOIN Users u ON a.user_id = u.user_id
GROUP BY u.username
ORDER BY total_calls DESC
LIMIT 10;

SELECT 
    m.model_name,
    AVG(a.latency_ms) AS avg_latency
FROM API_Calls a
JOIN LLM_Models m ON a.model_id = m.model_id
GROUP BY m.model_name
ORDER BY avg_latency DESC;

SELECT 
    severity,
    COUNT(*) AS total_incidents
FROM Incidents
GROUP BY severity
ORDER BY total_incidents DESC;

SELECT 
    s.system_name,
    v.severity,
    v.cve_id
FROM Vulnerabilities v
JOIN Systems s ON v.system_id = s.system_id
WHERE v.severity IN ('HIGH', 'CRITICAL');

SELECT 
    t.team_name,
    COUNT(i.incident_id) AS incident_count
FROM Incidents i
JOIN Systems s ON i.system_id = s.system_id
JOIN Organizations o ON i.org_id = o.org_id
JOIN Teams t ON o.org_id = t.org_id
GROUP BY t.team_name
ORDER BY incident_count DESC
LIMIT 10;

SELECT *
FROM Cost_Records
WHERE total_cost_usd > (
    SELECT AVG(total_cost_usd) FROM Cost_Records
);

UPDATE Users
SET role = 'senior_engineer'
WHERE user_id IN (
    SELECT user_id FROM Users
    ORDER BY RANDOM()
    LIMIT 10
);

DELETE FROM Vulnerabilities
WHERE is_patched = TRUE
AND reported_at < NOW() - INTERVAL '90 days';

INSERT INTO Organizations (org_name, industry, country)
VALUES ('TestOrg', 'AI', 'USA');



