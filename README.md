# CareSync - Hospital Management System
**Connecting Care. Simplifying Healthcare.**

CareSync is a full-stack, offline-capable Hospital Management System (HMS) featuring a modern cross-platform Flutter frontend and a robust Spring Boot backend.

---

## Project Structure

```text
hospital/
├── frontend/                     # CareSync Flutter Client Application
│   ├── lib/                      # Clean Architecture UI, State, Domain, and Data
│   ├── assets/                   # CareSync branding, images, and fonts
│   ├── test/                     # 66 comprehensive unit and widget test suites
│   ├── android/                  # Android native project (APKs & AABs)
│   ├── ios/                      # iOS native project (IPAs)
│   ├── web/                      # Web platform (PWA)
│   ├── macos/                    # macOS desktop project (DMG)
│   ├── linux/                    # Linux desktop project (DEB, ZIP, AppImage)
│   ├── windows/                  # Windows desktop project (EXE installer & ZIP)
│   └── pubspec.yaml              # Flutter dependencies and configuration
│
├── backend/                      # CareSync Spring Boot Backend
│   ├── src/main/java/            # Spring Boot application source code
│   │   └── com/caresync/backend/ # Application classes, controllers, and services
│   ├── src/main/resources/       # application.properties, schema & configurations
│   ├── src/test/java/            # Spring Boot JUnit 5 test suites
│   ├── pom.xml                   # Maven dependencies and build definition
│   └── mvnw, mvnw.cmd            # Maven wrapper scripts
│
├── .github/                      # GitHub Actions CI/CD workflows
│   └── workflows/
│       └── build-release.yml     # Automated multi-platform build runner & release
└── README.md                     # Monorepo documentation
```

---

## 1. Frontend (Flutter)

### Running the Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### Running Frontend Tests
```bash
cd frontend
flutter test
```

### Key Frontend Features
- **CareSync Branding & Identity**: Clean, responsive design with official CareSync logo and branding.
- **Super Admin & Multi-Hospital Management**: Super Admin account capable of managing, registering, and switching between multiple hospital entities and branches in real-time.
- **Strict Role-Based Access Control (RBAC)**: Fine-grained permissions that dynamically enable and disable features, navigation items, and action buttons across Super Admin, Admin, Doctor, Nurse, Receptionist, Pharmacist, Lab Technician, Accounts, and Staff.
- **Dynamic Bed & Ward Board**: Full CRUD bed management (Add Bed, Edit Bed, Delete Bed, Ward allocation, daily tariffs, and live occupancy status).
- **OPD & IPD Management**: Outpatient queue, consultations, vitals, admissions, and ward bed allocations.
- **Pharmacy & POS**: Medicine inventory management, low-stock warnings, dispensing, and sales checkout.
- **Appointments & Queues**: Token generation, scheduling, status tracking, and doctor duty assignments.
- **Billing & Invoicing**: Automated invoice calculation, itemized charges, and payment tracking.
- **EMR & Patient Registry**: Complete patient demographics, medical history, allergies, and emergency contacts.
- **Audit Logging & Security**: Session timeouts, auto-lock PIN security, and tamper-evident audit logs.
- **Offline First**: Fully functional without internet connectivity using embedded local SQLite.

### Default Client Credentials
- **Super Admin (Multi-Hospital)**: `superadmin` / `SuperAdmin@1234`
- **Hospital Admin**: `admin` / `Admin@1234`
- **Doctor**: `doctor` / `Doctor@1234`
- **Nurse**: `nurse` / `Nurse@1234`
- **Reception**: `reception` / `Reception@1234`
- **Pharmacy**: `pharmacy` / `Pharmacy@1234`
- **Laboratory**: `lab` / `Lab@1234`
- **Accounts**: `accounts` / `Accounts@1234`
- **Staff**: `user` / `User@1234`

---

## 2. Backend (Spring Boot)

### Technologies
- Spring Boot 4.x / Java 21+
- Spring Web MVC, Spring Data JPA, Spring Security, Spring Validation, Spring Boot Actuator
- In-memory H2 Database for local development (configurable to PostgreSQL / MySQL)

### Running the Backend
```bash
cd backend
./mvnw spring-boot:run
```
*(On Windows: `mvnw.cmd spring-boot:run` or `mvn spring-boot:run`)*

### Running Backend Tests
```bash
cd backend
./mvnw clean test
```

### Backend Ports & Endpoints
- **Server Port**: `http://localhost:8080`
- **H2 Console**: `http://localhost:8080/h2-console`
  - JDBC URL: `jdbc:h2:mem:caresyncdb`
  - Username: `sa`
  - Password: *(empty)*
- **Actuator Health & Metrics**: `http://localhost:8080/actuator/health`
