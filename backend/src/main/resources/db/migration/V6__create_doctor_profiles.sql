-- Composite parent key prevents a Doctor Profile from referencing another Hospital's membership.
ALTER TABLE hospital_memberships
    ADD CONSTRAINT uk_membership_id_hospital UNIQUE (membership_id, hospital_uuid);

CREATE TABLE doctor_profiles (
    doctor_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    membership_id UUID NOT NULL,
    department_uuid UUID,
    specialization VARCHAR(120) NOT NULL,
    qualification VARCHAR(160) NOT NULL,
    registration_reference VARCHAR(120),
    active BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    record_version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT pk_doctor_profiles PRIMARY KEY (doctor_uuid),
    CONSTRAINT uk_doctor_profile_id_hospital UNIQUE (doctor_uuid, hospital_uuid),
    CONSTRAINT uk_doctor_profile_membership UNIQUE (membership_id),
    CONSTRAINT fk_doctor_profile_hospital FOREIGN KEY (hospital_uuid) REFERENCES hospitals(hospital_uuid),
    CONSTRAINT fk_doctor_profile_membership_hospital FOREIGN KEY (membership_id, hospital_uuid)
        REFERENCES hospital_memberships(membership_id, hospital_uuid),
    CONSTRAINT fk_doctor_profile_department_hospital FOREIGN KEY (department_uuid, hospital_uuid)
        REFERENCES departments(department_uuid, hospital_uuid)
);

CREATE INDEX ix_doctor_profile_hospital_active_name
    ON doctor_profiles(hospital_uuid, active, specialization);
CREATE INDEX ix_doctor_profile_membership
    ON doctor_profiles(membership_id);
