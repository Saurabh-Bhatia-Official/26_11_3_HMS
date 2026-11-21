# CareSync Backend Module Ownership

This file records module ownership and the state observed in the repository on 15 November 2026. Package directories containing only `package-info.java` are placeholders; they do not constitute implemented modules.

## Status definitions

- **IMPLEMENTED:** The module has working backend behavior in source code.
- **PARTIALLY IMPLEMENTED:** Some shared or supporting behavior exists, but the module capability is incomplete.
- **PROPOSED:** A design/assignment exists, but no implementation was found.
- **NOT IMPLEMENTED:** No corresponding backend implementation was found. A package placeholder does not change this status.

## Ownership and current implementation status

| Area | Owner | Status | Repository evidence / boundary |
|---|---|---|---|
| Common backend foundation | Trupti | PARTIALLY IMPLEMENTED | Existing Spring Boot application and security code. `common/*` currently contains package-info placeholders only. `ApiResponse`, `TenantContextHolder`, and `TenantContextUtil` were not found. |
| Authentication and security integration | Trupti | IMPLEMENTED (authentication baseline) | Existing `/api/auth/login`, `/refresh`, `/logout`, `/me`; see `security/*`. This does not mean hospital discovery/login, membership, or business authorization is complete. |
| Patient Registry | Trupti | NOT IMPLEMENTED | `patient/controller`, `patient/service`, and `patient/repository` contain package-info placeholders only; no patient backend endpoint/entity/service/repository was found. |
| Appointments | Trupti | NOT IMPLEMENTED | One `appointment/controller` package-info placeholder; no appointment backend implementation found. |
| OPD | Trupti | NOT IMPLEMENTED | No OPD backend implementation found. |
| Hospital enrollment and Hospital | Kedar | NOT IMPLEMENTED | No Hospital entity, repository, service, or controller found in backend. `AuthAccount.hospitalId` is a scalar, not a Hospital relationship. |
| Membership | Kedar | NOT IMPLEMENTED | No membership entity, repository, service, or controller found. |
| Laboratory orders and results | Parvi | NOT IMPLEMENTED | No laboratory backend implementation found. |
| Flutter/local workflows | Existing local application owners | PARTIALLY IMPLEMENTED locally | Not an online backend module; do not infer backend capability from local UI/SQLite. |

## Shared contracts: observed state

| Contract/component | State | Source-backed detail |
|---|---|---|
| Authentication principal | IMPLEMENTED | `BearerTokenFilter.AuthPrincipal` nested record contains user ID, username, full name, role, and nullable hospital ID. |
| Security roles | IMPLEMENTED | `SecurityRole` enum: `SUPER_ADMIN`, `ADMIN`, `DOCTOR`, `NURSE`, `RECEPTIONIST`, `PHARMACIST`, `LAB_TECHNICIAN`, `ACCOUNTS`, `STAFF`. This is not an action-level permission matrix. |
| JWT request filter | IMPLEMENTED | `BearerTokenFilter` decodes bearer JWT and asks `AuthService.authenticate` to validate current account state. |
| Hospital context | PARTIALLY IMPLEMENTED | Hospital ID is carried as a scalar on account/principal/token and checked for equality. No membership model, hospital lookup, or dedicated tenant context holder/util exists. |
| API response format | PARTIALLY IMPLEMENTED | Auth uses `AuthDtos.TokenResponse`, `UserResponse`, and `ErrorResponse`. No general `ApiResponse` class/envelope found. |
| Exception handling | IMPLEMENTED for current auth API | `security/ApiExceptionHandler` maps validation, unreadable request, unsupported method/media type, and unexpected exceptions to `AuthDtos.ErrorResponse`. No shared module exception hierarchy found. |
| Validation namespace | IMPLEMENTED with Jakarta | `AuthDtos` imports `jakarta.validation.constraints.*`; `pom.xml` includes `spring-boot-starter-validation`. Do not document `javax.validation` for this project. |
| Authentication audit | IMPLEMENTED for current auth events | `SecurityAuditEvent` stores event type, nullable account ID, and timestamp; it is not a general business `AuditEvent` abstraction. |
| General audit event abstraction | NOT IMPLEMENTED | No `AuditEvent` class/interface found. |

## Shared-file ownership and coordination

- Trupti owns common backend and authentication/security integration changes. Coordinate review for any change to existing auth contracts or security configuration.
- Kedar owns Hospital and Membership design/implementation when approved. Hospital/membership schema and migration ownership stays with Kedar; no migration is authorized by this ownership file.
- Parvi owns Laboratory orders/results and consumes the approved tenant and patient contracts; Parvi must not create a separate hospital or membership model.
- Cross-module API DTOs, error conventions, principal/tenant contracts, and shared configuration require agreement among affected owners before implementation.
- Existing `security/*` classes remain in place. No duplicate authentication, Hospital, Membership, or tenant-context implementation should be created.
- Developers must preserve pre-existing work and avoid editing files outside their assigned ownership without coordination.

## Dependency order

1. Agree database/migration decisions and Hospital/Membership tenant contract (Kedar; security review by Trupti).
2. Agree patient identifiers and tenant-aware API contract (Trupti, consuming Kedar's contract).
3. Implement Laboratory orders/results against those reviewed contracts (Parvi).
4. Appointment and OPD work follows the patient/tenant foundation; it is not part of the initial three-module slice.

All APIs and schema not evidenced in current backend source remain proposed until implemented and tested.
