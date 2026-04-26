# SecureAI Analytics Database

A PostgreSQL relational database schema for monitoring **LLM API usage, costs, security incidents, and vulnerabilities** across multi-tenant organizations. Designed for teams that need centralized visibility into AI infrastructure operations and cybersecurity posture.

---

## Overview

This database models a security and observability platform for organizations consuming large language model APIs. It tracks:

- API usage and token consumption across models and teams
- Cost attribution per team and billing period
- Security incidents, attack types, and mitigation actions
- Infrastructure vulnerabilities linked to systems and LLM models

---

## Schema

The database consists of 11 core tables plus an audit log table:

| Table | Description |
|---|---|
| `Organizations` | Top-level tenants, segmented by industry and country |
| `Teams` | Sub-units within an organization (Engineering, SOC, ML, etc.) |
| `Users` | Individual users assigned to teams with roles (engineer, analyst, admin, soc_analyst) |
| `LLM_Models` | Catalog of supported models with per-1k-token pricing (OpenAI, Anthropic, Google, etc.) |
| `Systems` | Infrastructure assets (servers, endpoints, API gateways, LLM middleware) |
| `API_Calls` | Individual LLM API call records with token counts, latency, and status codes |
| `Cost_Records` | Per-call cost breakdown (input/output/total) attributed to teams and billing periods |
| `Vulnerabilities` | CVE-linked vulnerability records tied to systems and LLM models |
| `Attack_Types` | MITRE ATT&CK-aligned taxonomy of attack categories |
| `Incidents` | Security incident records linked to organizations, systems, and attack types |
| `Mitigation_Actions` | Response actions taken per incident, logged by user |
| `Failed_Transaction_Log` | Audit log for rejected cost records (trigger-generated) |

### Entity Relationship Summary

Organizations
├── Teams
│   └── Users
│       └── API_Calls → Cost_Records
└── Systems
├── Vulnerabilities
└── Incidents
├── Attack_Types
└── Mitigation_Actions

---

## Features

**Cost Tracking**
Costs are automatically computed from token usage and model pricing rates. The `add_api_call_with_cost()` stored function atomically inserts an API call and its corresponding cost record in a single transaction.

**Data Integrity via Triggers**
A `BEFORE INSERT OR UPDATE` trigger on `Cost_Records` rejects any record with a negative `total_cost_usd` and logs the failure to `Failed_Transaction_Log`.

**Performance Indexes**
Three indexes are included to accelerate common analytical queries:
- `idx_cost_records_team_id` — speeds up team-level spend aggregations
- `idx_api_calls_model_id` — speeds up per-model latency queries
- `idx_vulnerabilities_system_severity` — speeds up HIGH/CRITICAL vulnerability lookups

**Realistic Seed Data**
The script seeds the database with synthetic but realistic data:
- 20 organizations across FinTech, Healthcare, Education, Retail, and Cybersecurity
- 100 teams, 500 users, 150 systems
- 2,500 API calls with auto-generated cost records
- 250 vulnerabilities, 150 incidents, 200 mitigation actions
- 10 real-world LLM models with current pricing

---

## Supported LLM Models

| Model | Provider |
|---|---|
| gpt-4o, gpt-4o-mini | OpenAI |
| claude-3-opus, claude-3-sonnet | Anthropic |
| gemini-1.5-pro, gemini-1.5-flash | Google |
| llama-3-70b | Meta |
| mistral-large | Mistral |
| command-r-plus | Cohere |
| deepseek-chat | DeepSeek |

---

## Getting Started

### Prerequisites

- PostgreSQL 13 or higher

### Setup

1. Clone the repository:
```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
```

2. Create a new database:
```bash
   createdb secureai_db
```

3. Run the schema and seed script:
```bash
   psql -d secureai_db -f main.sql
```

---

## Example Queries

**Top 10 teams by LLM spend:**
```sql
SELECT t.team_name, SUM(c.total_cost_usd) AS total_spend
FROM Cost_Records c
JOIN Teams t ON c.team_id = t.team_id
GROUP BY t.team_name
ORDER BY total_spend DESC
LIMIT 10;
```

**Average latency by model:**
```sql
SELECT m.model_name, AVG(a.latency_ms) AS avg_latency
FROM API_Calls a
JOIN LLM_Models m ON a.model_id = m.model_id
GROUP BY m.model_name
ORDER BY avg_latency DESC;
```

**Unpatched HIGH/CRITICAL vulnerabilities:**
```sql
SELECT s.system_name, v.cve_id, v.severity
FROM Vulnerabilities v
JOIN Systems s ON v.system_id = s.system_id
WHERE v.severity IN ('HIGH', 'CRITICAL') AND v.is_patched = FALSE;
```

**Incident count by severity:**
```sql
SELECT severity, COUNT(*) AS total_incidents
FROM Incidents
GROUP BY severity
ORDER BY total_incidents DESC;
```

---

## License

MIT
