
CREATE TABLE staff_departments (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    hospital_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_department_hospital_name
        UNIQUE (hospital_id, name)
);

CREATE INDEX ix_staff_departments_hospital
    ON staff_departments (hospital_id, is_deleted);

CREATE TABLE staff (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL UNIQUE,
    hospital_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    name VARCHAR(160) NOT NULL,
    gender VARCHAR(16) NOT NULL,
    date_of_birth DATE,
    phone VARCHAR(32) NOT NULL,
    email VARCHAR(254),
    address VARCHAR(500) NOT NULL DEFAULT '',
    role VARCHAR(32) NOT NULL,
    department_id BIGINT REFERENCES staff_departments(id),
    qualification VARCHAR(160) NOT NULL DEFAULT '',
    registration_number VARCHAR(64),
    photo_path VARCHAR(500),
    specialisation VARCHAR(160) NOT NULL DEFAULT '',
    consultation_fee_paise BIGINT NOT NULL DEFAULT 0,
    followup_fee_paise BIGINT NOT NULL DEFAULT 0,
    followup_days INTEGER NOT NULL DEFAULT 7,
    max_slots_per_day INTEGER NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX ix_staff_hospital
    ON staff (hospital_id, is_deleted);

CREATE INDEX ix_staff_hospital_role
    ON staff (hospital_id, role, is_deleted);
