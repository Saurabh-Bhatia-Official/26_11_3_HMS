ALTER TABLE patients
    ADD CONSTRAINT uk_patient_id_hospital UNIQUE (patient_id, hospital_uuid);

CREATE TABLE appointments (
    appointment_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    patient_id BIGINT NOT NULL,
    doctor_uuid UUID NOT NULL,
    department_uuid UUID,
    created_by_membership_id UUID NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    appointment_type VARCHAR(40) NOT NULL,
    reason VARCHAR(500),
    notes VARCHAR(2000),
    status VARCHAR(16) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    record_version BIGINT NOT NULL,
    CONSTRAINT pk_appointments PRIMARY KEY (appointment_uuid),
    CONSTRAINT uk_appointment_id_hospital UNIQUE (appointment_uuid, hospital_uuid),
    CONSTRAINT fk_appointment_hospital FOREIGN KEY (hospital_uuid) REFERENCES hospitals(hospital_uuid),
    CONSTRAINT fk_appointment_patient_hospital FOREIGN KEY (patient_id, hospital_uuid)
        REFERENCES patients(patient_id, hospital_uuid),
    CONSTRAINT fk_appointment_doctor_hospital FOREIGN KEY (doctor_uuid, hospital_uuid)
        REFERENCES doctor_profiles(doctor_uuid, hospital_uuid),
    CONSTRAINT fk_appointment_department_hospital FOREIGN KEY (department_uuid, hospital_uuid)
        REFERENCES departments(department_uuid, hospital_uuid),
    CONSTRAINT fk_appointment_creator_membership_hospital FOREIGN KEY (created_by_membership_id, hospital_uuid)
        REFERENCES hospital_memberships(membership_id, hospital_uuid),
    CONSTRAINT ck_appointment_time CHECK (starts_at < ends_at),
    CONSTRAINT ck_appointment_status CHECK
        (status IN ('SCHEDULED', 'CONFIRMED', 'CHECKED_IN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'))
);

CREATE INDEX ix_appointment_hospital_start ON appointments(hospital_uuid, starts_at);
CREATE INDEX ix_appointment_doctor_start_status ON appointments(hospital_uuid, doctor_uuid, starts_at, status);
CREATE INDEX ix_appointment_patient_start ON appointments(hospital_uuid, patient_id, starts_at);

CREATE TABLE appointment_events (
    event_uuid UUID NOT NULL,
    appointment_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    actor_membership_id UUID NOT NULL,
    event_type VARCHAR(24) NOT NULL,
    previous_status VARCHAR(16),
    new_status VARCHAR(16),
    previous_starts_at TIMESTAMP WITH TIME ZONE,
    previous_ends_at TIMESTAMP WITH TIME ZONE,
    new_starts_at TIMESTAMP WITH TIME ZONE,
    new_ends_at TIMESTAMP WITH TIME ZONE,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_appointment_events PRIMARY KEY (event_uuid),
    CONSTRAINT fk_appointment_event_appointment_hospital FOREIGN KEY (appointment_uuid, hospital_uuid)
        REFERENCES appointments(appointment_uuid, hospital_uuid),
    CONSTRAINT fk_appointment_event_actor_hospital FOREIGN KEY (actor_membership_id, hospital_uuid)
        REFERENCES hospital_memberships(membership_id, hospital_uuid)
);

CREATE INDEX ix_appointment_events_hospital_appointment_time
    ON appointment_events(hospital_uuid, appointment_uuid, occurred_at);
