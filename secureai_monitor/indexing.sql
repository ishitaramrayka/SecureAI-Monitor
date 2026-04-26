-- indexing 

ROLLBACK;

-- index 1
EXPLAIN ANALYZE
SELECT 
    t.team_name,
    SUM(c.total_cost_usd) AS total_spend
FROM Cost_Records c
JOIN Teams t ON c.team_id = t.team_id
GROUP BY t.team_name
ORDER BY total_spend DESC
LIMIT 10;

CREATE INDEX idx_cost_records_team_id
ON Cost_Records(team_id);

-- index 2
EXPLAIN ANALYZE
SELECT 
    m.model_name,
    AVG(a.latency_ms) AS avg_latency
FROM API_Calls a
JOIN LLM_Models m ON a.model_id = m.model_id
GROUP BY m.model_name
ORDER BY avg_latency DESC;

CREATE INDEX IF NOT EXISTS idx_api_calls_model_id
ON API_Calls(model_id);

-- index 3

EXPLAIN ANALYZE
SELECT 
    s.system_name,
    v.cve_id,
    v.severity,
    v.is_patched
FROM Vulnerabilities v
JOIN Systems s ON v.system_id = s.system_id
WHERE v.severity IN ('HIGH', 'CRITICAL')
ORDER BY v.reported_at DESC;

CREATE INDEX IF NOT EXISTS idx_vulnerabilities_system_severity
ON Vulnerabilities(system_id, severity);