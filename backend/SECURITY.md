# CareSync backend security

This document describes the current backend code. It is not a compliance certification or production-readiness approval. The backend does not access or synchronize the Flutter Drift database.

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

## Business API and authorization

Accepted account roles are centralized in `SecurityRole`: `SUPER_ADMIN`, `ADMIN`, `DOCTOR`, `NURSE`, `RECEPTIONIST`, `PHARMACIST`, `LAB_TECHNICIAN`, `ACCOUNTS`, and `STAFF`. Current route permissions are:

- `/api/staff/**`: `ADMIN`, `SUPER_ADMIN`.
- `/api/billing/**`: `ADMIN`, `SUPER_ADMIN`, `ACCOUNTS`.
- `/api/pharmacy/**`: `ADMIN`, `SUPER_ADMIN`, `PHARMACIST`.
- `/api/lab/tests/**`: test catalogue reads allow `ADMIN`, `SUPER_ADMIN`, `LAB_TECHNICIAN`, `DOCTOR`; changes allow only `ADMIN`, `SUPER_ADMIN`, `LAB_TECHNICIAN`.
- `/api/lab/orders`: order creation allows `ADMIN`, `SUPER_ADMIN`, `DOCTOR`; reads also allow `LAB_TECHNICIAN`; collection, result entry, verification, and delivery allow `ADMIN`, `SUPER_ADMIN`, `LAB_TECHNICIAN`.
- `/api/reports/**`: `ADMIN`, `SUPER_ADMIN`, `ACCOUNTS`.

Business endpoints require a hospital-scoped authenticated account. Unmapped routes remain denied by default. Frontend role checks do not grant backend access. These permissions are an initial policy and should be reviewed by the hospital before deployment.

The implemented business routes are:

| Group | Resources and actions |
| --- | --- |
| `/api/staff` | Department and staff CRUD; optional `role` filter |
| `/api/billing` | Service catalogue, invoice creation/list/detail/cancel, payments |
| `/api/pharmacy` | Suppliers, medicine catalogue, batches, stock receive/adjustment, dispensing |
| `/api/lab` | Test catalogue and parameters; order, collect, process, result, verify, deliver |
| `/api/reports` | Date-range summary/revenue and stock alerts |

JSON request/response field names are camelCase. Prices are integer paise. Invoice totals and pharmacy dispensing totals are calculated by the server; clients cannot submit a final total or payment receiver ID.

## Hospital scope and tenant isolation

Login derives scope from the persisted account; clients cannot choose a hospital in login, refresh, or `/me`. Non-super-admin accounts require a positive hospital ID, and protected requests compare token and current account scope. The `SUPER_ADMIN` account may have no hospital scope in the authentication model.

Business records carry a `hospital_id`, and repository lookups include the authenticated account's hospital ID. A record from a different hospital is returned as not found. The backend still has no hospital entity/table, account-to-hospital foreign key, hospital provisioning flow, or hospital-switching endpoint, so it cannot validate that a configured hospital ID exists. A `SUPER_ADMIN` token with no hospital ID cannot access business records; cross-hospital super-admin operations are not implemented. Patient, visit, admission, and prescription IDs are external references because those modules are outside the current API scope; the backend cannot validate their existence or hospital ownership. Do not treat these references as foreign-key validation.

## HTTP and management controls

- CORS reads exact comma-separated HTTP(S) origins from `CARESYNC_CORS_ALLOWED_ORIGINS`. It rejects `*`, allows only configured origins, and does not allow credentials. An empty setting disables cross-origin browser access. Configure each environment separately.
- Spring Security adds frame, content-type, content-security, referrer, and permissions policy headers. TLS/HSTS must be configured at the trusted HTTPS gateway; the backend does not claim to enforce public HTTPS.
- Request headers and Tomcat form/multipart payloads are bounded by application properties. These settings do not impose a complete JSON body limit; configure a JSON request-size limit at the gateway.
- Only the Actuator health endpoint is exposed. Health details are hidden. The legacy H2 console is disabled.
- There is no IP-based rate limiter. Account lockout does not prevent distributed attacks. Configure and test gateway or infrastructure rate limits for login and refresh before public exposure; do not rely on untrusted forwarded IP headers.
- Unexpected application errors return a generic response and log only the exception type. Do not log request bodies or tokens. Existing logs do not intentionally include authentication secrets.

## Database and migrations

The default datasource is file-backed SQLite at `./data/caresyncdb.sqlite`; Hibernate uses `ddl-auto=update`. Activate the `neon` Spring profile to use a Neon PostgreSQL JDBC URL (`NEON_JDBC_URL`), username (`NEON_DB_USERNAME`), and password (`NEON_DB_PASSWORD`). The Neon URL should include `sslmode=require`. Schema changes are currently managed by Hibernate entity updates; no versioned migration runner exists. Before production schema evolution, introduce reviewed, versioned migrations and test them against disposable SQLite and PostgreSQL databases.

`src/main/resources/db/migration/auth_security_hardening.sql` is a prepared additive authentication script, tested against isolated H2 only. It is not automatically run and does not replace a versioned database migration strategy.

The backend SQLite file is separate from the Flutter app's local Drift database. There is no client synchronization or conflict-resolution protocol yet.

## Bootstrap and environment

`CARESYNC_BOOTSTRAP_USERNAME` and `CARESYNC_BOOTSTRAP_PASSWORD` can create the first account only when the auth account table is empty; the password must be at least 12 characters. By default it is an unscoped `SUPER_ADMIN`. Set `CARESYNC_BOOTSTRAP_HOSPITAL_ID` to a positive numeric ID to create a hospital-scoped `ADMIN` that can use the business APIs. Remove bootstrap variables after provisioning. There is no account, hospital, or role administration API. Provisioning, secrets, durable database, backups, key rotation, TLS, gateway body limits, and rate limits must be reviewed before deployment.

## Tests

Run backend tests from `backend/` with `mvn test`. Authentication/business API tests use isolated H2; a persistence test also boots the mapped schema against in-memory SQLite. These tests do not connect to Neon and are not a substitute for deployment and migration rehearsal.
