# CareSync backend security

This document describes the current backend code. It is not a compliance certification or production-readiness approval. The backend does not access or modify Flutter Drift/SQLite.

## Authentication API

| Method | Path | Access | Behavior |
| --- | --- | --- | --- |
| POST | `/api/auth/login` | Public | Verifies credentials; returns a 15-minute access token and 30-day refresh token. |
| POST | `/api/auth/refresh` | Public | Rotates refresh token and issues a new access token. |
| POST | `/api/auth/logout` | Public | Revokes the supplied refresh token. |
| GET | `/api/auth/me` | Authenticated supported role | Returns the current account and hospital scope. |

Login accepts `{"username":"...","password":"..."}`. Refresh and logout accept `{"refreshToken":"..."}`. Existing route and JSON contracts are unchanged. Invalid credentials use a generic 401 response; invalid JSON/request bodies return a generic 400 response. Security failures return generic JSON 401 or 403 responses.

## JWT and account lifecycle

- `CARESYNC_JWT_SECRET` must contain at least 32 UTF-8 bytes. The application fails startup if it is absent or too short. Use a random secret from a secret manager; do not commit it. Changing the secret invalidates outstanding access tokens. Key rotation procedure is an infrastructure responsibility and is not implemented.
- Spring Security Nimbus signs and verifies HS256 tokens. Validation checks signature and algorithm, issuer, audience, required claims and strict integer claim types, issued-at, expiry, lifetime, and 30-second clock skew.
- Passwords use BCrypt with work factor 12. Five failed attempts lock an account for 15 minutes. On lock expiry, the next login starts a fresh attempt window; a successful login resets the counter. Unknown, inactive, locked and invalid-credential login responses do not disclose account state.
- Protected requests reload the account and check active status, supported role, hospital scope, and token version. Role or hospital assignment changes make old token claims fail validation. Deactivation increments token version.
- Refresh tokens are cryptographically random, stored as SHA-256 hashes, and rotated transactionally. Requests serialize on the account row. Replaying a revoked token revokes its family. Expired refresh rows are cleaned every six hours; expired ancestors are retained while their family may still be replayed.
- Logout revokes refresh renewal. Existing stateless access tokens remain valid until their 15-minute expiry unless the account is deactivated or its current authorization state changes.
- Security audit records contain event type, account ID when known, and timestamp. They do not contain credentials, token values, usernames, IP addresses, or patient data. Audit retention and tamper protection are not configured.

## Roles and authorization

Accepted account roles are centralized in `SecurityRole`: `SUPER_ADMIN`, `ADMIN`, `DOCTOR`, `NURSE`, `RECEPTIONIST`, `PHARMACIST`, `LAB_TECHNICIAN`, `ACCOUNTS`, and `STAFF`. All supported roles may access only their own `/api/auth/me` response. Public auth routes are explicitly permitted. **Unmapped routes are denied by default**; a future endpoint must receive an explicit server-side policy before it becomes accessible.

There are no implemented business controllers or role-to-operation permission rules in this backend. Product owners must confirm which roles may create, read, update, or delete each business resource before those endpoint policies can be added. Frontend role checks do not grant backend access.

## Hospital scope and tenant isolation

Login derives scope from the persisted account; clients cannot choose a hospital in login, refresh, or `/me`. Non-super-admin accounts require a positive hospital ID, and protected requests compare token and current account scope. The `SUPER_ADMIN` account may have no hospital scope in the authentication model.

There is no hospital entity/table, account-to-hospital foreign key, hospital provisioning flow, hospital switching endpoint, or business resource repository in the current backend. Hospital existence and cross-hospital resource isolation therefore cannot yet be enforced or tested. Do not treat the current auth scope checks as proof of business-data tenant isolation. Do not add a fake hospital model; establish the real schema and policy first. A super-admin's cross-hospital operating policy requires product-owner confirmation before business endpoints are added.

## HTTP and management controls

- CORS reads exact comma-separated HTTP(S) origins from `CARESYNC_CORS_ALLOWED_ORIGINS`. It rejects `*`, allows only configured origins, and does not allow credentials. An empty setting disables cross-origin browser access. Configure each environment separately.
- Spring Security adds frame, content-type, content-security, referrer, and permissions policy headers. TLS/HSTS must be configured at the trusted HTTPS gateway; the backend does not claim to enforce public HTTPS.
- Request headers and Tomcat form/multipart payloads are bounded by application properties. These settings do not impose a complete JSON body limit; configure a JSON request-size limit at the gateway.
- Only the Actuator health endpoint is exposed. Health details are hidden. H2 console is disabled.
- There is no IP-based rate limiter. Account lockout does not prevent distributed attacks. Configure and test gateway or infrastructure rate limits for login and refresh before public exposure; do not rely on untrusted forwarded IP headers.
- Unexpected application errors return a generic response. Do not log request bodies or tokens. Existing logs do not intentionally include authentication secrets.

## Database and migrations

The default datasource is in-memory H2 and Hibernate uses `ddl-auto=update`. This is development configuration, not a selected production persistence strategy. No production database is identified in the repository, and no migration runner or versioned migration history exists.

`src/main/resources/db/migration/auth_security_hardening.sql` is the sole prepared, additive authentication schema script. It adds `token_version` with default zero, nullable refresh `family_id`, indexes, and the audit table. A test applies it only to isolated H2 with representative existing auth rows and confirms those rows remain. This does not establish PostgreSQL/MySQL compatibility. The script has not been applied to any development, production, or external database, and is not automatically run.

Before adopting it, select the actual database and migration tool, compare the script against that database's schema, assign a versioned migration name, rehearse against a disposable copy, and take a verified backup. Rollback should preserve the added data and leave additive columns/tables in place unless a separately reviewed data-retention plan says otherwise; do not use destructive rollback in production.

## Bootstrap and environment

`CARESYNC_BOOTSTRAP_USERNAME` and `CARESYNC_BOOTSTRAP_PASSWORD` can create the initial super-admin only when the auth account table is empty; the password must be at least 12 characters. Remove these variables after provisioning. There is no account, hospital, or role administration API. Provisioning, secrets, durable database, backups, key rotation, TLS, gateway body limits, and rate limits must be reviewed before deployment.

## Tests

Run backend tests from `backend/` with `mvn test`. Authentication and migration tests use named in-memory H2 databases and do not target a configured development or production database. Tests do not substitute for authorization tests against business endpoints; none exist yet.
