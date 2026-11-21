-- Hospital-local time zone is deliberately nullable: existing Hospitals must be configured explicitly.
ALTER TABLE hospitals ADD COLUMN time_zone VARCHAR(64);

CREATE TABLE departments (
    department_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(500),
    active BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_departments PRIMARY KEY (department_uuid),
    CONSTRAINT uk_department_id_hospital UNIQUE (department_uuid, hospital_uuid),
    CONSTRAINT fk_department_hospital FOREIGN KEY (hospital_uuid) REFERENCES hospitals(hospital_uuid)
);

CREATE UNIQUE INDEX uk_department_active_code
    ON departments(hospital_uuid, lower(code))
    WHERE active = TRUE;
CREATE INDEX ix_department_hospital_active_name
    ON departments(hospital_uuid, active, name);
