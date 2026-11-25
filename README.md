# CareSync – Hospital Management System

**Connecting Care. Simplifying Healthcare.**

CareSync is a full-stack, offline-capable Hospital Management System (HMS) featuring a modern cross-platform Flutter frontend and a Spring Boot backend.

## Project Structure

```text
HMS_project_complex/
├── frontend/                     # CareSync Flutter application
│   ├── lib/                      # UI, State, Domain and Data layers
│   ├── assets/                   # Images and branding
│   ├── test/                     # Unit and widget tests
│   ├── android/                  # Android platform
│   ├── ios/                      # iOS platform
│   ├── web/                      # Web application (PWA)
│   ├── macos/                    # macOS platform
│   ├── linux/                    # Linux platform
│   ├── windows/                  # Windows platform
│   └── pubspec.yaml              # Flutter dependencies
│
├── backend/                      # Spring Boot backend
│   ├── src/main/java/            # Java application source
│   ├── src/main/resources/       # Application configuration
│   ├── src/test/java/            # Backend tests
│   ├── pom.xml                   # Maven configuration
│   ├── mvnw                      # Maven wrapper (Linux/macOS)
│   └── mvnw.cmd                  # Maven wrapper (Windows)
│
├── .github/
│   └── workflows/                # GitHub Actions workflows
│       └── build-release.yml
│
├── .gitignore
├── feature.md
└── README.md

```

## 1. Frontend – Flutter

### Technologies
- Flutter
- Dart
- SQLite
- Cross-platform development

### Running the Frontend

Open the VS Code terminal:

```bash
cd frontend
flutter pub get
```

On Windows:

```powershell
.\run_web.bat
```

Alternatively, use VS Code Run and Debug and select the CareSync Web configuration.
These default launch options use the local database, so the demo credentials shown
on the sign-in screen work without a backend account.

### Running Frontend Tests

```bash
cd frontend
flutter test
```

### Key Features

- **CareSync Branding:** Modern, responsive user interface.
- **Multi-Hospital Management:** Super Admin can manage and switch between hospitals and branches.
- **Role-Based Access Control (RBAC):** Permissions for Admin, Doctor, Nurse, Receptionist, Pharmacist, Lab Technician, Accounts and Staff.
- **Patient Management:** Patient registration, demographics, medical history and allergies.
- **OPD & IPD Management:** Outpatient queues, consultations, admissions and bed allocation.
- **Appointment Management:** Scheduling, token generation and status tracking.
- **Pharmacy Management:** Medicine inventory, dispensing and sales.
- **Billing & Invoicing:** Itemized charges, invoice calculation and payment tracking.
- **Bed & Ward Management:** Bed allocation, occupancy tracking and ward management.
- **Audit Logging & Security:** Session timeout, auto-lock and audit logs.
- **Offline Support:** Local SQLite database for offline functionality.

## 2. Backend – Spring Boot

### Technologies

- Java 21+
- Spring Boot 4.x
- Spring Web MVC
- Spring Data JPA
- Spring Security
- JWT-based authentication
- Spring Validation
- Spring Boot Actuator
- SQLite for local backend development
- Neon PostgreSQL for server deployments

### Running the Backend

From the repository root, start the backend in PowerShell with:

```powershell
.\backend\run-local.cmd
```

The backend listens on port `12223` by default. The local launcher allows the Flutter web origin `http://localhost:12221` unless `CARESYNC_CORS_ALLOWED_ORIGINS` is already set. It also generates a fresh random JWT secret on every run, replacing any value inherited from the current shell. The generated key is kept in memory and is not saved or committed; restarting the backend invalidates tokens from the previous run. Production must provide its own private secret of at least 32 bytes through `CARESYNC_JWT_SECRET`.

Alternatively, run Maven directly from `backend/`. The `spring-boot:run` goal activates the `local` profile and generates a new ephemeral JWT secret if `CARESYNC_JWT_SECRET` is not set:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

The ephemeral key is never saved and changes on each start. For non-local deployments, set a private `CARESYNC_JWT_SECRET` of at least 32 UTF-8 bytes; the application fails startup if it is missing or too short.

### Running Backend Tests

```bash
cd backend
.\mvnw.cmd clean test
```

### Backend Endpoints

| Service | URL |
|---|---|
| Backend Server | http://localhost:12223 |
| Health Check | http://localhost:12223/actuator/health |

### Database Configuration

- Local backend database: `jdbc:sqlite:./data/caresyncdb.sqlite`
- SQLite files persist under `backend/data/`.
- The Flutter app retains its own local SQLite database. Existing local history is not uploaded when connecting an account.

### Connecting the Flutter App

Start the backend, provision a backend account, then run Flutter with the backend origin:

```powershell
cd frontend
flutter run -d chrome --web-port=12221 --dart-define=CARESYNC_API_BASE_URL=http://localhost:12223
```

Sign in with the provisioned backend credentials to enable remote reads for staff, lab orders, pharmacy stock resources, invoices, and supported report aggregates. If the backend is unreachable, those screens fall back to their local SQLite data. Local-only accounts and data remain separate from backend accounts and records.

Patient creation, OPD visit starts, and IPD admissions from a backend-authenticated session are queued with stable UUID references and retried on the next backend login. Existing local history is not bulk-uploaded, and edits to visits/admissions are not synchronized. Other mutations—including staff, prescriptions, lab orders/results, pharmacy stock/dispensing, and invoices/payments—remain local-only unless sent directly to the backend APIs. Remote responses are not cached to SQLite, and conflict resolution and audited opening-stock import are not yet implemented.

For Neon, configure `NEON_JDBC_URL` as a JDBC PostgreSQL URL with TLS enabled, along with `NEON_DB_USERNAME` and `NEON_DB_PASSWORD`, then start with the `neon` profile:

```powershell
cd backend
$env:NEON_JDBC_URL = "jdbc:postgresql://<neon-host>/<database>?sslmode=require&channel_binding=require"
$env:NEON_DB_USERNAME = "<database-user>"
$securePassword = Read-Host "Neon DB password" -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $env:NEON_DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
}
$env:CARESYNC_CORS_ALLOWED_ORIGINS = "http://localhost:12221"
$secretBytes = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $rng.GetBytes($secretBytes)
    $env:CARESYNC_JWT_SECRET = [Convert]::ToBase64String($secretBytes)
} finally {
    $rng.Dispose()
}
.\mvnw.cmd "-Dspring-boot.run.profiles=neon" spring-boot:run
```

Use a newly rotated database password; never commit or paste connection credentials into source files. Stop any running local backend first because the Neon profile uses the same server port. Hibernate currently updates the schema from the JPA entities at startup. Review and add versioned migrations before evolving a production database.

### Backend Authentication

The backend requires `CARESYNC_JWT_SECRET` to be set to a unique random value of at least 32 bytes before startup. The initial account can be provisioned by setting `CARESYNC_BOOTSTRAP_USERNAME` and `CARESYNC_BOOTSTRAP_PASSWORD` (at least 12 characters). Set `CARESYNC_BOOTSTRAP_HOSPITAL_ID` to a positive numeric ID to create a hospital-scoped `ADMIN`; if omitted, the account is a `SUPER_ADMIN` without access to hospital-scoped records. Remove bootstrap credentials after the account is created.

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/auth/login` | Authenticate and issue access/refresh tokens |
| POST | `/api/auth/refresh` | Rotate refresh tokens |
| POST | `/api/auth/logout` | Revoke a refresh token |
| GET | `/api/auth/me` | Return the authenticated account |

Business APIs are available under `/api/staff`, `/api/patients`, `/api/visits`, `/api/admissions`, `/api/prescriptions`, `/api/billing`, `/api/pharmacy`, `/api/lab`, and `/api/reports`. They require a bearer access token and hospital-scoped account; authorization is role-based and each business row is filtered by the account's hospital ID.

| API group | Main resources |
|---|---|
| `/api/patients` | Patient identity lookup and creation by stable UUID |
| `/api/visits` | Hospital-scoped visit references created by stable UUID |
| `/api/admissions` | Admission references linked to the same patient's visit |
| `/api/prescriptions` | Prescription references linked to a hospital-scoped visit |
| `/api/staff` | Departments and staff records |
| `/api/billing` | Service catalogue, invoices, and payments |
| `/api/pharmacy` | Suppliers, medicines, batches, stock adjustments, and dispensing |
| `/api/lab` | Test catalogue, lab orders, results, verification, and delivery |
| `/api/reports` | Summary, daily revenue, and low-stock alerts |

Unmapped backend routes are denied by default. Configure browser origins through `CARESYNC_CORS_ALLOWED_ORIGINS`. See [backend/SECURITY.md](backend/SECURITY.md) for authorization, request shapes, data scope, and deployment limitations.

## 3. Development and Testing

The project uses a modular architecture with separate frontend and backend components.

Developers can run and test each component independently.

**Frontend:**
```bash
cd frontend
flutter pub get
flutter test
```

**Backend:**
```bash
cd backend
.\mvnw.cmd clean test
```

## 4. Security Notice

Any sample credentials used for local development should be changed before deployment.

Do not commit real passwords, API keys, database credentials or private configuration files to GitHub.

## 5. Project Information

**Project Name:** CareSync – Hospital Management System

**Repository:** HMS_project_complex

**Frontend:** Flutter

**Backend:** Spring Boot

**Database:** SQLite / H2 (with configurable database support)

---

**CareSync – Connecting Care. Simplifying Healthcare.**
