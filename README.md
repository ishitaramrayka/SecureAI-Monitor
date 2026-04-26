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
