# MCP-1 — DealCloud MCP Connector (Read-Only)

> SOW Reference: `TBS-TB-AI-2026-MCP1`
> Derived from: `DealCloud MCP Connector: Build Spec (Wave 1, Read-Only)`
> Duration: 36 days (7–8 weeks) | Team: 1 senior engineer | Prerequisites: F1 (AI Landing Zone) deployed, DealCloud sandbox access
> Wave: 1 (Read-Only) | Target: Production pilot with scoped Entra group

---

## 1. Purpose

Deploy an MCP (Model Context Protocol) server into the AI Landing Zone that enables Claude users to query DealCloud data in real time — scoped to each user's existing DealCloud permissions — without any manual data extraction, CSV exports, or direct DealCloud UI navigation.

Wave 1 is read-only. One MCP connector registered in Claude for Work. Six DealCloud service accounts behind it, each mapped to a DealCloud user group. The connector routes each user request to the appropriate service account based on the calling user's group memberships. DealCloud enforces all row-level, field-level, and entry-group-level access natively.

**Key outcome:** Any authorised Thoma Bravo user can ask Claude natural-language questions about deals, companies, contacts, funds, and investors — and receive answers grounded in live DealCloud data, filtered to exactly what that user is permitted to see.

No SCIM dependency. No permission replication in the connector. No semantic modelling layer.

---

## 2. Architecture

```text
Claude (user auth via Entra SSO)
   │
   │  OAuth bearer (user-scoped to connector app)
   ▼
MCP Connector  ── AKS Pod (private VNet, no public ingress)
   │                 namespace: mcp-dealcloud
   │                 workload identity → Key Vault
   │
   │  1. Validate user JWT, extract identity
   │  2. Call DealCloud user API → get user's group memberships (via router SA)
   │  3. Pick data service account by priority waterfall
   │  4. Call DealCloud data API with chosen SA's client credentials
   ▼
DealCloud REST API  (https://<tenant>.dealcloud.com/api/rest/...)
```

### 2.1 Deployment Target

| Aspect | Configuration |
|--------|--------------|
| Runtime | AKS private cluster (existing from F1) |
| Namespace | `mcp-dealcloud` (dedicated, RBAC-isolated) |
| Identity | Workload Identity (federated credential → Managed Identity → Key Vault) |
| Ingress | Internal only (ClusterIP or internal NGINX — no public exposure) |
| Container Registry | ACR Premium (existing from F1, Private Endpoint) |
| Secrets | Azure Key Vault (existing from F1, accessed via Managed Identity CSI driver) |
| Observability | Application Insights + Log Analytics (existing from F1) |

### 2.2 Why AKS (Not Container Apps)

The AI Landing Zone AKS cluster is already provisioned, networked, and monitored. Deploying the MCP connector as a pod in a dedicated namespace:

- Avoids provisioning a Container Apps Environment (~$150–300/month saved)
- Reuses existing networking (VNet, NSGs, UDRs, Private DNS)
- Reuses existing observability (OMS agent, App Insights, Log Analytics)
- Reuses existing ACR pull credentials (Managed Identity)
- Aligns with the platform deployment model for all other AI workloads (agents, APIs)

Incremental Azure cost: **effectively $0** — the pod is lightweight and runs on existing node capacity.

---

## 3. Dependencies

### 3.1 Prerequisites (Before Day 1)

- [ ] F1 AI Landing Zone deployed: AKS cluster, Key Vault, ACR, networking, monitoring
- [ ] DealCloud sandbox tenant access (API credentials for validation)
- [ ] Personal API access to DealCloud sandbox (for Tony's validation sequence)
- [ ] Entra ID app registration approved by IT/Security
- [ ] Claude for Work MCP connector registration process understood

### 3.2 External Dependencies (During Build)

| Dependency | Owner | Blocks Phase | Impact if Delayed |
|------------|-------|-------------|-------------------|
| Sandbox validation (especially step 7 — scoping proof) | Tony | All production work | **Critical** — if DealCloud doesn't enforce scoping per SA token, entire design needs revisiting |
| 6 Service Accounts provisioned in DealCloud production | Lauren + Niv | Phases 5–9 (production) | Can build and test against sandbox; production cut-over blocked |
| Dual-membership user list + override decisions | Niv | Phase 3 (routing overrides) | Default waterfall works; per-user overrides incomplete |
| Entra app registration + API scope approval | IT/Security | Phase 2 (auth layer) | Can mock auth locally; integration blocked |
| DLP/Purview egress configuration at landing zone level | Infra team | Phase 9 (go-live) | Connector works; compliance gate not met |

### 3.3 Downstream Consumers

- Claude for Work (MCP client) — sole consumer in Wave 1
- Future: additional MCP tools (Wave 1.x: saved views; Wave 2: write-back, multi-step agentic)

---

## 4. Technical Design

### 4.1 Authentication — Dual-Leg Model

Two distinct OAuth flows. No user delegation. No On-Behalf-Of. User identity never reaches DealCloud directly.

#### Leg 1: User → Connector (Entra ID)

| Aspect | Detail |
|--------|--------|
| Protocol | OAuth 2.0 / OpenID Connect |
| Identity Provider | Azure Entra ID (TB tenant) |
| Flow | Claude authenticates the user via Entra SSO, issues a bearer token scoped to the connector's API |
| Connector validates | JWT signature, audience (`api://<connector-app-id>`), issuer, expiry |
| Claims extracted | `oid` (user object ID), `preferred_username` (email), `groups` (optional, for future RBAC) |

#### Leg 2: Connector → DealCloud (Client Credentials)

| Aspect | Detail |
|--------|--------|
| Protocol | OAuth 2.0 Client Credentials |
| Token endpoint | `POST /api/rest/v1/oauth/token` |
| Credentials | `client_id` + `client_secret` per service account (stored in Key Vault) |
| Token caching | Per SA, cached until TTL expiry. Refreshed proactively before expiry |
| Scopes | `user_management` (router SA only), `data` (all five data SAs) |

### 4.2 Service Accounts

Six accounts. Each provisioned in DealCloud by Lauren/Niv into exactly one named group. The connector holds `client_id` and `client_secret` for each in Key Vault (12 secrets total).

| Service Account | DealCloud Group Membership | Scope | Purpose |
|----------------|---------------------------|-------|---------|
| `svc-ai-mcp-router` | API Access (or minimal) | `user_management` (read) | Look up calling user's DealCloud group memberships. No data reads. |
| `svc-ai-mcp-elevated` | Platform (Read Only) | `data` | Cross-barrier read. Sees everything. For IT, Platform Managers. |
| `svc-ai-mcp-credit` | Credit Team | `data` | Credit + Equity deal-side visibility (Credit coverage is broader by design). |
| `svc-ai-mcp-equity` | Equity Deal Teams | `data` | Equity-side only. Cannot see Credit-restricted data. |
| `svc-ai-mcp-ir` | Investor Relations | `data` | Fund/LP/IR side only. No deal-side detail. |
| `svc-ai-mcp-standard` | (no data-granting group) | `data` | Schema + broadly-operational data only. Fallback tier. |

**Rule:** Do not mix group memberships. Each SA lives in exactly one group. DealCloud inherits both field-level and entry-group-level partitioning from that group automatically.

### 4.3 Routing Logic

For each incoming MCP tool call:

1. Extract user email from the Entra JWT (`preferred_username` claim).
2. Call `GET /api/rest/v1/management/user?email=<email>` via router SA. Cache response per user for 10 minutes.
3. From the returned `groups` array, apply priority waterfall:

```text
if user in [Platform (Read Only), IT Leadership, TB Platform Manager]:
    → svc-ai-mcp-elevated

elif user in [Credit Team]:
    → svc-ai-mcp-credit        # broader than Equity; handles dual-members

elif user in [Equity Deal Teams, Growth Senior Team Members]:
    → svc-ai-mcp-equity

elif user in [Investor Relations, Investor Relations (Read Only), Private Wealth]:
    → svc-ai-mcp-ir

else:
    → svc-ai-mcp-standard
```

4. Execute the downstream DealCloud call with the chosen SA's token.
5. Log: user email, chosen SA, tool invoked, DealCloud request/response status, correlation ID.

#### Dual-Membership Edge Cases

Users in groups spanning deal and IR sides need explicit decisions. Niv will provide a list during provisioning. Configuration supports per-user-email overrides that force a specific SA or force elevated. If no override exists, the waterfall defaults to the more restrictive match (higher in the priority list = broader access, so dual-members get the broader tier).

#### Cache Invalidation

Subscribe to DealCloud publications feed (`/api/rest/v1/publication/poll`) for user/group change events. On any change, invalidate cached membership for affected users. Fallback: 10-minute TTL expiry if publications feed is unavailable.

### 4.4 MCP Tools (Wave 1)

One tool at launch. Additional tools added as Wave 1 progresses.

#### `query_entries`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `entry_type` | string | Yes | Singular name or ApiName (e.g., "Deal", "Company", "Contact") |
| `filters` | array | No | `[{ field, operation, value }, ...]` |
| `fields` | array | No | Field names to return. If omitted, return default entry-form fields. |
| `limit` | int | No | Default 50, max 500 |

**Implementation sequence:**

1. Resolve `entry_type` → `entryTypeId` via cached schema (bootstrapped at startup).
2. Resolve each filter's `field` → `fieldId`. Resolve choice values to IDs.
3. Resolve `operation` to filter op enum ID.
4. Build `FilterInfoVm[]` payload.
5. `POST /api/rest/v4/data/entrydata/{entryTypeId}/filter` with the payload, using chosen SA token.
6. Resolve returned entry IDs to rows via `POST /api/rest/v4/data/entrydata/rows/query/{entryTypeId}`.
7. Return rows (or count if `limit=0`).

**Input validation:** Refuse queries against `entry_type` that the chosen SA is not authorised to read (cached from schema introspection per SA). Return an auth-scoped error the model can reformulate around.

### 4.5 Schema Bootstrap

On connector start and every 24 hours:

| Endpoint | Purpose | Cache Key |
|----------|---------|-----------|
| `GET /api/rest/v4/schema/entrytypes` | Entry type catalog | By ID and ApiName |
| `GET /api/rest/v4/schema/allfields` | Field metadata (includes `isStoreRequestSupported`, `isCalculated`, `systemFieldType`, `choiceFieldId`, `choiceValues`) | By ID, per entry type |
| `GET /api/rest/v4/schema/filteroperations` | Filter operation ID map | By op name |
| `GET /api/rest/v4/schema/users` (activeOnly=true) | User directory for name resolution | By ID and email |

Also subscribes to publications feed for schema-change events; re-bootstraps on receipt.

### 4.6 DealCloud API Endpoints (Wave 1 — Complete List)

| Endpoint | Method | Purpose | SA |
|----------|--------|---------|-----|
| `/api/rest/v1/oauth/token` | POST | SA authentication | All |
| `/api/rest/v1/management/user` | GET | User group lookup | Router |
| `/api/rest/v4/schema/entrytypes` | GET | Entry type catalog | Data SAs |
| `/api/rest/v4/schema/allfields` | GET | Field catalog | Data SAs |
| `/api/rest/v4/schema/filteroperations` | GET | Filter op IDs | Data SAs |
| `/api/rest/v4/schema/users` | GET | User directory | Data SAs |
| `/api/rest/v4/data/entrydata/{id}/filter` | POST | Filter → entry IDs | Data SAs |
| `/api/rest/v4/data/entrydata/rows/query/{id}` | POST | Entry ID → row data | Data SAs |
| `/api/rest/v4/data/rows/view` | GET | List saved views | Data SAs |
| `/api/rest/v4/data/rows/view/{viewId}` | POST | Execute saved view | Data SAs |
| `/api/rest/v1/publication/topics` | GET | Available change topics | Router |
| `/api/rest/v1/publication/poll` | POST | Poll for changes | Router |
| `/api/rest/v1/publication/acknowledge` | POST | Acknowledge processed events | Router |

### 4.7 Audit Logging

Every DealCloud request/response pair is logged as structured JSON, keyed by a correlation ID that flows from the MCP tool call through SA selection to the downstream HTTP call.

| Field | Description |
|-------|-------------|
| `correlationId` | Unique ID per MCP tool invocation |
| `timestamp` | ISO 8601 |
| `userEmail` | Calling user (from Entra JWT) |
| `serviceAccount` | Which SA was selected |
| `toolName` | MCP tool invoked (e.g., `query_entries`) |
| `entryType` | DealCloud entry type queried |
| `dcEndpoint` | DealCloud API endpoint called |
| `dcMethod` | HTTP method |
| `dcStatusCode` | DealCloud response status |
| `dcLatencyMs` | Round-trip time to DealCloud |
| `rowCount` | Number of rows returned |
| `error` | Error message (if any) |

Sink: Application Insights (existing) → Log Analytics Workspace (existing). No additional infrastructure required.

### 4.8 DLP Integration

Outbound responses from the connector pass through Purview classification and DLP policy before reaching Claude. This is handled at the Landing Zone egress layer, not in connector code. However, the connector must preserve classification labels on returned field values — no stripping, no transformation of labelled content.

---

## 5. Infrastructure Requirements

### 5.1 What Already Exists (from F1)

All core infrastructure is deployed and operational:

| Component | Status | Used By MCP Connector |
|-----------|--------|-----------------------|
| AKS Private Cluster (Azure CNI Overlay, 3 pools) | Deployed | Pod runtime |
| Workload Identity (OIDC issuer enabled) | Deployed | Key Vault access |
| ACR Premium (Private Endpoint) | Deployed | Container image storage |
| Key Vault Premium (Private Endpoint, RBAC) | Deployed | SA credentials (12 secrets) |
| VNet `10.52.0.0/16` (peered to hub, Palo Alto routing) | Deployed | Network isolation |
| NSGs (deny-all default, explicit allows) | Deployed | Traffic control |
| Log Analytics Workspace | Deployed | Audit log sink |
| Application Insights (workspace-based) | Deployed | Telemetry, traces, metrics |
| Private DNS Zones | Deployed | Internal name resolution |

### 5.2 What Needs to Be Created

| Component | Scope | Effort |
|-----------|-------|--------|
| Kubernetes namespace `mcp-dealcloud` | RBAC: ServiceAccount, Role, RoleBinding | 0.5 days |
| Workload Identity federation | Federated credential linking K8s SA → Managed Identity → Key Vault | 1 day |
| Key Vault secrets | 12 entries: `dc-sa-router-client-id`, `dc-sa-router-client-secret`, ... (×6 SAs) | 0.5 days |
| Helm chart / K8s manifests | Deployment, Service, HPA, ConfigMap, SecretProviderClass | 1 day |
| Dockerfile | Multi-stage build, optimised for size | 0.5 days |
| Entra app registration | API scopes, redirect URIs, consent configuration | External (IT/Security) |

### 5.3 Incremental Azure Cost

| Item | Monthly Cost |
|------|-------------|
| AKS pod (1–2 replicas on existing nodes) | $0 (existing capacity) |
| Key Vault operations (~100 secret reads/day, cached) | < $1 |
| Log Analytics ingestion (audit logs, ~50 MB/day) | $5–15 |
| Application Insights ingestion | $5–10 |
| ACR storage (1 container image, ~200 MB) | < $1 |
| **Total incremental** | **~$10–25/month** |

> The MCP connector adds negligible cost to the existing Landing Zone. All expensive infrastructure (AKS, VNet, Key Vault, monitoring) is already provisioned and paid for.

---

## 6. Build Phases and Effort Estimate

### 6.1 Phase Summary

| # | Phase | Days | Cumulative |
|---|-------|------|-----------|
| 1 | Infrastructure & Deployment Scaffold | 3.5 | 3.5 |
| 2 | Authentication Layer (Dual-Leg) | 5 | 8.5 |
| 3 | Routing Logic & Membership Cache | 4.5 | 13 |
| 4 | Schema Bootstrap & Cache Management | 4.5 | 17.5 |
| 5 | Tool: `query_entries` | 4.5 | 22 |
| 6 | Observability & Audit Logging | 2.5 | 24.5 |
| 7 | Testing (Unit + Integration + Sandbox) | 7 | 31.5 |
| 8 | Claude Integration & Pilot | 4.5 | 36 |
| **Total** | | **36 days** | |

### 6.2 Detailed Phase Breakdown

#### Phase 1 — Infrastructure & Deployment Scaffold (3.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Kubernetes namespace + RBAC (ServiceAccount, Role, RoleBinding) | 0.5 | `namespace.yaml`, `rbac.yaml` |
| Workload Identity: federated credential → Managed Identity → Key Vault access policy | 1.0 | Terraform config or `az` CLI scripts |
| Key Vault: 12 secrets (client_id + client_secret × 6 SAs) | 0.5 | Secret entries (values provided by Lauren/Niv) |
| Helm chart or K8s manifests (Deployment, Service, HPA, ConfigMap, SecretProviderClass) | 1.0 | `helm/` or `k8s/` directory |
| Dockerfile (multi-stage) + ACR build pipeline | 0.5 | `Dockerfile`, pipeline YAML |

#### Phase 2 — Authentication Layer (5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Entra app registration configuration (API scopes, audience, redirect URIs) | 0.5 | App registration manifest |
| Inbound JWT validation middleware (signature, audience, issuer, expiry, claims extraction) | 2.0 | Auth middleware module |
| Outbound DealCloud OAuth client_credentials flow | 1.5 | DC auth client module |
| Per-SA token cache with TTL management (proactive refresh before expiry) | 1.0 | Token cache service |

#### Phase 3 — Routing Logic & Membership Cache (4.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| User group membership lookup via router SA (`GET /management/user?email=`) | 1.0 | Membership resolver |
| Priority waterfall SA selection (5-tier logic) | 1.0 | Router service |
| Per-user membership cache (10-minute TTL) | 0.5 | Cache layer |
| Per-email override config (force SA for dual-membership users) | 0.5 | Override config loader |
| Cache invalidation via DealCloud publications feed (`/publication/poll`, `/acknowledge`) | 1.5 | Publications subscriber |

#### Phase 4 — Schema Bootstrap & Cache Management (4.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Entry types fetch + cache (`/schema/entrytypes`) | 0.5 | Schema cache |
| Field catalog fetch + cache (`/schema/allfields`) with choice value resolution | 1.5 | Field resolver |
| Filter operations cache (`/schema/filteroperations`) | 0.5 | Filter op mapper |
| Users cache for name resolution (`/schema/users`) | 0.5 | User resolver |
| Daily refresh scheduler | 0.5 | Background task |
| Publications feed subscription for schema-change events → re-bootstrap | 1.0 | Schema invalidation |

#### Phase 5 — Tool: `query_entries` (4.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Entry type resolution (name/ApiName → `entryTypeId`) | 0.5 | Resolver |
| Field resolution + choice value → ID mapping for filters | 1.0 | Filter builder |
| Filter operation resolution + `FilterInfoVm[]` payload construction | 1.0 | Payload serialiser |
| `POST filter` → entry IDs → `POST rows/query` two-step execution | 1.0 | Query executor |
| Input validation: SA authorisation check against per-SA schema introspection | 0.5 | Auth validator |
| MCP response formatting (structured rows, metadata, pagination hints) | 0.5 | Response formatter |

#### Phase 6 — Observability & Audit Logging (2.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Structured JSON audit logging (every call, no exceptions) | 1.0 | Logging middleware |
| Correlation ID propagation (MCP call → SA selection → DealCloud HTTP → response) | 0.5 | Correlation context |
| Application Insights integration (custom metrics, dependency tracking) | 0.5 | Telemetry config |
| Health checks + readiness/liveness probes for Kubernetes | 0.5 | `/health`, `/ready` endpoints |

> Note: reduced from 3.5 days in the Container Apps estimate — AKS already has OMS agent, container logging, and App Insights wired from F1.

#### Phase 7 — Testing (7 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Unit tests: routing logic (waterfall, overrides, edge cases) | 1.5 | Test suite |
| Unit tests: schema resolution (entry types, fields, choice values) | 1.0 | Test suite |
| Unit tests: auth flows (JWT validation, token cache, SA selection) | 0.5 | Test suite |
| Integration tests: mock DealCloud API (contract tests, error scenarios) | 2.0 | Test suite + mock server |
| Sandbox validation sequence (7 steps — see §7) | 2.0 | Validation report |

#### Phase 8 — Claude Integration & Pilot (4.5 days)

| Task | Days | Deliverable |
|------|------|-------------|
| Register MCP connector in Claude for Work | 0.5 | Registration config |
| Scope connector to pilot Entra security group | 0.5 | Access policy |
| Test pass with Lauren: representative queries through each SA tier | 1.5 | Test report |
| Bug fixing and adjustments from pilot feedback | 1.5 | Patch releases |
| Documentation: operational runbook (scaling, secret rotation, troubleshooting) | 0.5 | Runbook |

### 6.3 Effort Scenarios

| Scenario | Days | Assumption |
|----------|------|-----------|
| **Optimistic** | 30 | DealCloud API behaves exactly as documented; sandbox validation passes first try; no dual-membership surprises |
| **Realistic** | 36 | Minor API quirks requiring workarounds; 1–2 edge cases in routing; normal iteration cycle |
| **Pessimistic** | 42 | DealCloud API scoping doesn't work as expected (partial redesign); publications feed has gaps; rate limit issues |

---

## 7. Sandbox Validation Sequence

This is the **critical-path prerequisite**. If step 7 fails, the entire design needs revisiting.

Run against DealCloud sandbox tenant using personal API access:

| Step | Test | Pass Criteria |
|------|------|---------------|
| 1 | **Auth** — Get token via client credentials | Token returns with expected scopes |
| 2 | **Schema** — Pull entry types, field catalog, filter ops | Response shape matches Swagger/docs |
| 3 | **Filter query** — `POST /data/entrydata/Deal/filter` with simple stage filter | Returns entry ID array |
| 4 | **Row fetch** — `POST /data/entrydata/rows/query/Deal` with entry IDs from step 3 | Returns typed rows with expected fields |
| 5 | **Saved view** — List views via `GET /data/rows/view`, execute one | Returns view data matching DealCloud UI |
| 6 | **Publications** — `GET /publication/topics`, `POST /publication/poll` | Returns event format suitable for cache invalidation |
| 7 | **Scoped access** — Repeat steps 3–4 with Equity-only token; verify Credit deals absent. Repeat with IR-only token; verify Fund/LP returns data, Deal returns empty/scoped | **DealCloud enforces row/field scoping per SA token** |

> **Step 7 is the lynchpin.** If DealCloud does not enforce access scoping on API tokens the way the design assumes, the SA-per-group model breaks and we would need to explore alternative approaches (field-level filtering in connector code, custom DealCloud views per tier, or a different permission model entirely). Validate this before committing to the full build.

---

## 8. Build Sequence (Chronological)

```text
Phase   Week 1          Week 2          Week 3          Week 4          Week 5          Week 6          Week 7-8
─────   ──────          ──────          ──────          ──────          ──────          ──────          ────────
1       ████░░░░░░
2       ░░░░████████████
3                       ░░░░░████████░░
4                       ░░░░░░░░░░░░████████░░
5                                       ░░░░████████░░
6                                       ░░░░░░░░░░░███░░
7                                                   ░░░░██████████████
8                                                                   ░░░░████████████

External: ─── Sandbox validation (Tony) ───|── SA provisioning (Lauren/Niv) ──|── Dual-membership list (Niv) ──
```

| Week | Activities | External Dependencies |
|------|-----------|----------------------|
| 1 | Phase 1 (infra scaffold) + Phase 2 start (auth) | Sandbox access needed |
| 2 | Phase 2 complete + Phase 3 (routing logic) | — |
| 3 | Phase 3 complete + Phase 4 (schema bootstrap) | Sandbox validation should complete |
| 4 | Phase 5 (query_entries tool) + Phase 6 (observability) | Dual-membership list from Niv |
| 5 | Phase 7 (testing — unit + integration) | — |
| 6 | Phase 7 complete (sandbox validation) | SA provisioning in production |
| 7–8 | Phase 8 (Claude integration + pilot + fixes) | Entra app approved; DLP/Purview configured |

---

## 9. Risks and Mitigations

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|-----------|
| R1 | **DealCloud API does not enforce scoping per SA token** (step 7 fails) | Medium | **Critical** — entire SA routing model invalid | Validate in sandbox before any build work. If scoping fails: explore DealCloud custom views per tier, or field-level filtering in connector. Escalate immediately. |
| R2 | **DealCloud rate limits hit during normal usage** | Medium | High — degraded user experience, 429 errors | 10-minute membership cache reduces router SA calls. Schema cached for 24h. Monitor and surface 429s as explicit user-facing errors. Request Intapp rate limit documentation. |
| R3 | **Publications feed does not cover user/group change topics** | Low | Medium — cache invalidation degrades to TTL-only | Acceptable fallback: 10-minute TTL means stale data window is bounded. Validate topic coverage in sandbox (step 6). |
| R4 | **DealCloud API response shapes differ from documentation** | Medium | Medium — additional mapping/transformation work | Sandbox validation steps 2–5 catch this early. Budget includes 2 days integration testing with mock server. |
| R5 | **Entra app registration approval delayed** | Medium | Medium — auth layer blocked | Can develop and test with mocked JWT validation locally. Real integration blocked but not on critical path until Phase 8. |
| R6 | **Dual-membership users produce unexpected access patterns** | Medium | Low–Medium — wrong tier served to some users | Override config allows per-email SA forcing. Niv's list addresses known cases. Audit logging catches anomalies post-launch. |
| R7 | **DealCloud SA client secret rotation disrupts service** | Low | Medium — temporary auth failures | Secrets in Key Vault, read at runtime. Rotation = update Key Vault secret, pod picks up new value on next cache miss. No code change, no redeployment. |
| R8 | **Claude for Work MCP registration has unexpected constraints** | Low | Medium — integration approach may need adjustment | Engage Anthropic support early (Week 1) to confirm registration requirements and connector specification format. |

---

## 10. Acceptance Criteria

### 10.1 Authentication

- [ ] Connector validates Entra JWT on every inbound request (signature, audience, issuer, expiry)
- [ ] Invalid/expired tokens return 401 with structured error
- [ ] Connector authenticates to DealCloud via client credentials for each of 6 SAs
- [ ] SA tokens are cached and reused within TTL; proactive refresh before expiry
- [ ] All 12 secrets (6 × client_id + client_secret) loaded from Key Vault via Workload Identity

### 10.2 Routing

- [ ] User email extracted from JWT maps to correct SA via priority waterfall
- [ ] Users in Platform/IT Leadership/TB Platform Manager groups → `svc-ai-mcp-elevated`
- [ ] Credit Team users → `svc-ai-mcp-credit`
- [ ] Equity Deal Teams / Growth Senior users → `svc-ai-mcp-equity`
- [ ] Investor Relations / Private Wealth users → `svc-ai-mcp-ir`
- [ ] All other authenticated users → `svc-ai-mcp-standard`
- [ ] Per-email overrides respected when configured
- [ ] Membership cache invalidated on DealCloud publications events or 10-minute TTL

### 10.3 Data Access

- [ ] `query_entries` tool correctly resolves entry types, fields, and filter operations from cached schema
- [ ] Filter queries return results consistent with DealCloud UI for the same user
- [ ] Row data matches field types (dates, currencies, choice lists resolve correctly)
- [ ] Queries against unauthorised entry types return auth-scoped error (not raw DealCloud error)
- [ ] Results respect `limit` parameter (default 50, max 500)

### 10.4 Security & Compliance

- [ ] No public ingress — connector accessible only within AKS cluster network
- [ ] No user credentials stored in connector — only SA credentials in Key Vault
- [ ] No DealCloud data cached in connector beyond response lifetime
- [ ] Audit log captures every DealCloud API call with correlation ID
- [ ] DLP/Purview classification labels preserved on returned field values

### 10.5 Observability

- [ ] Every MCP tool call produces a structured audit log entry in Application Insights
- [ ] Correlation ID traces from Claude request → SA selection → DealCloud API call → response
- [ ] Health check endpoint (`/health`) returns 200 when connector can reach DealCloud and Key Vault
- [ ] Readiness probe (`/ready`) returns 200 only after schema bootstrap completes
- [ ] Metrics: request count, latency (p50/p95/p99), error rate, SA distribution, cache hit rate

### 10.6 Operational

- [ ] Pod scales via HPA (1–3 replicas based on request rate)
- [ ] SA secret rotation requires only Key Vault update — no code change, no redeployment
- [ ] Schema refresh runs automatically every 24 hours and on publications events
- [ ] Operational runbook delivered covering: scaling, secret rotation, cache management, troubleshooting, log queries

---

## 11. Out of Scope (Wave 1)

| Item | Target Wave | Notes |
|------|------------|-------|
| Write-back (create/update/delete entries) | Wave 2 | Separate approval model, different SA scopes |
| Additional persona-matched SAs (Growth Senior as own tier, IR Credit-Only) | Wave 2 | Conditional on usage patterns from Wave 1 |
| Multi-step tool chaining / agentic workflows | Wave 2+ | Requires orchestration layer |
| Unstructured text search over Notes/Interactions | Wave 2 | Requires separate indexing layer (AI Search) |
| Saved views tool (`query_view`) | Wave 1.x | Lower priority; can be added after initial launch |
| Custom DealCloud dashboards or visualisation | N/A | Out of MCP scope entirely |
| SCIM provisioning or permission sync | N/A | Design explicitly avoids this |

---

## 12. Technology Stack Decision

### Recommended: Python

| Factor | Python | TypeScript | C# (.NET) |
|--------|--------|-----------|-----------|
| MCP SDK maturity | Official SDK, production-ready | Community SDK, stable | Newer, less mature |
| DealCloud API client | `httpx` / `aiohttp` — lightweight | `axios` / `fetch` — lightweight | `HttpClient` — verbose |
| Auth libraries | `PyJWT`, `msal` — battle-tested | `jsonwebtoken`, `@azure/msal-node` | `Microsoft.Identity.Web` |
| Container size | ~50 MB (Alpine) | ~80 MB (Node Alpine) | ~150 MB (SDK image) |
| Team alignment | Fastest to build and iterate | Good alternative | Aligns with .NET backend (future) |
| Async model | `asyncio` — native | Event loop — native | `async/await` — native |

**Recommendation:** Python for Wave 1. Fastest path to production with the most mature MCP SDK. If the broader platform standardises on .NET for all services (post-F1), a Wave 2 rewrite to C# is straightforward — the connector is stateless and small (~2,000 lines of application code).

---

## 13. Operational Notes

### Secret Rotation

DealCloud SA client secrets rotate quarterly. Connector reads from Key Vault at runtime (cached with TTL). Rotation procedure:

1. Lauren/Niv generate new client secret in DealCloud
2. Infra team updates Key Vault secret value
3. Pod picks up new secret on next cache miss (within minutes)
4. No code change. No redeployment. No downtime.

### Rate Limits

Intapp applies per-tenant rate limits (not publicly documented). Router SA lookups are the highest-volume call; 10-minute membership cache should keep well under any limit. Strategy:

- Monitor for 429 responses
- Surface as explicit user-facing error ("DealCloud is rate-limiting requests, please retry in a few minutes")
- If sustained: increase cache TTLs, add request queuing

### Scaling

| Load | Replicas | Notes |
|------|----------|-------|
| Pilot (5–10 users) | 1 | Sufficient for initial launch |
| Department rollout (50–100 users) | 2 | HPA triggers on request rate |
| Firm-wide (200+ users) | 3 | May need to review DealCloud rate limits |

---

## 14. Cost Summary

### Development Cost

| Scenario | Days | At $X/day |
|----------|------|-----------|
| Optimistic | 30 | 30 × rate |
| **Realistic** | **36** | **36 × rate** |
| Pessimistic | 42 | 42 × rate |

> Rate to be filled in per engagement terms.

### Azure Infrastructure Cost (Incremental Monthly)

| Item | Cost |
|------|------|
| Compute (AKS pod on existing nodes) | $0 |
| Key Vault operations | < $1 |
| Log Analytics ingestion | $5–15 |
| Application Insights | $5–10 |
| ACR storage | < $1 |
| **Total** | **~$10–25/month** |

### Total Cost of Ownership (Year 1)

| Item | Cost |
|------|------|
| Development (36 days) | 36 × rate |
| Azure infrastructure (12 months × ~$20) | ~$240 |
| Ongoing maintenance (estimated 2 days/quarter) | 8 × rate |
| **Total Year 1** | **(36 + 8) × rate + $240** |

---

## 15. Appendix: DealCloud API Reference

### Authentication

```
POST /api/rest/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id={id}&client_secret={secret}&scope={scope}
```

### User Group Lookup

```
GET /api/rest/v1/management/user?email={email}
Authorization: Bearer {router-sa-token}

Response: { "id": 123, "email": "...", "groups": [{ "id": 1, "name": "Credit Team" }, ...] }
```

### Filter Query (Two-Step)

```
# Step 1: Get entry IDs matching filter
POST /api/rest/v4/data/entrydata/{entryTypeId}/filter
Authorization: Bearer {data-sa-token}
Content-Type: application/json

{
  "Filters": [
    { "FieldId": 456, "FilterOperationId": 1, "Value": "Active" }
  ],
  "Limit": 50
}

# Step 2: Get row data for entry IDs
POST /api/rest/v4/data/entrydata/rows/query/{entryTypeId}
Authorization: Bearer {data-sa-token}
Content-Type: application/json

{
  "EntryIds": [101, 102, 103],
  "FieldIds": [456, 789, 1011]
}
```

### Publications Feed

```
# List available topics
GET /api/rest/v1/publication/topics
Authorization: Bearer {router-sa-token}

# Poll for changes
POST /api/rest/v1/publication/poll
Authorization: Bearer {router-sa-token}
Content-Type: application/json

{ "TopicIds": [1, 2, 3], "LastEventId": "..." }

# Acknowledge processed events
POST /api/rest/v1/publication/acknowledge
Authorization: Bearer {router-sa-token}
Content-Type: application/json

{ "EventIds": ["evt-1", "evt-2"] }
```
