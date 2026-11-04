# CareSync - Hospital Management System
**Connecting Care. Simplifying Healthcare.**

An offline-first, production-ready Hospital Management System (HMS) built with Flutter, Riverpod, Drift (SQLite), and Material Design 3.

## Features
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

## Default Credentials
- **Super Admin (Multi-Hospital)**: `superadmin` / `SuperAdmin@1234`
- **Hospital Admin**: `admin` / `Admin@1234`
- **Doctor**: `doctor` / `Doctor@1234`
- **Nurse**: `nurse` / `Nurse@1234`
- **Reception**: `reception` / `Reception@1234`
- **Pharmacy**: `pharmacy` / `Pharmacy@1234`
- **Laboratory**: `lab` / `Lab@1234`
- **Accounts**: `accounts` / `Accounts@1234`
- **Staff**: `user` / `User@1234`
