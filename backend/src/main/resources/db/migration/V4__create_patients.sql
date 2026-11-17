-- Additive Patient Registry schema. Requires the existing hospitals and auth_accounts baseline.
-- Do not run against production until that PostgreSQL baseline has been verified and approved.
CREATE SEQUENCE patient_id_sequence START WITH 1 INCREMENT BY 1;

CREATE TABLE patients (
    patient_id BIGINT NOT NULL,
    patient_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    uhid VARCHAR(30) NOT NULL,
    name VARCHAR(200) NOT NULL,
    gender VARCHAR(16),
    date_of_birth DATE,
    age_years INTEGER,
    phone VARCHAR(32),
    alternate_phone VARCHAR(32),
    email VARCHAR(254),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(32),
    blood_group VARCHAR(3),
    emergency_contact_name VARCHAR(160),
    emergency_contact_phone VARCHAR(32),
    status VARCHAR(16) NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_by_account_id BIGINT NOT NULL,
    updated_by_account_id BIGINT NOT NULL,
    record_version BIGINT NOT NULL,
    CONSTRAINT pk_patients PRIMARY KEY (patient_id),
    CONSTRAINT uk_patient_uuid UNIQUE (patient_uuid),
    CONSTRAINT uk_patient_hospital_uhid UNIQUE (hospital_uuid, uhid),
    CONSTRAINT fk_patient_hospital FOREIGN KEY (hospital_uuid) REFERENCES hospitals(hospital_uuid),
    CONSTRAINT fk_patient_created_by FOREIGN KEY (created_by_account_id) REFERENCES auth_accounts(id),
    CONSTRAINT fk_patient_updated_by FOREIGN KEY (updated_by_account_id) REFERENCES auth_accounts(id),
    CONSTRAINT ck_patient_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_patient_gender CHECK (gender IS NULL OR gender IN ('Male', 'Female', 'Other')),
    CONSTRAINT ck_patient_age CHECK (age_years IS NULL OR age_years BETWEEN 0 AND 150)
);

CREATE INDEX ix_patient_hospital_status_created
    ON patients(hospital_uuid, status, created_at DESC);
CREATE INDEX ix_patient_hospital_name
    ON patients(hospital_uuid, name);
CREATE INDEX ix_patient_hospital_phone
    ON patients(hospital_uuid, phone);
