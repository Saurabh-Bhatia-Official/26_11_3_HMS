CREATE TABLE doctor_schedules (
    schedule_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    doctor_uuid UUID NOT NULL,
    day_of_week INTEGER NOT NULL,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
    end_time TIME WITHOUT TIME ZONE NOT NULL,
    slot_minutes INTEGER NOT NULL,
    effective_from DATE NOT NULL,
    effective_until DATE,
    active BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_doctor_schedules PRIMARY KEY (schedule_uuid),
    CONSTRAINT uk_doctor_schedule_id_hospital UNIQUE (schedule_uuid, hospital_uuid),
    CONSTRAINT fk_doctor_schedule_profile_hospital FOREIGN KEY (doctor_uuid, hospital_uuid)
        REFERENCES doctor_profiles(doctor_uuid, hospital_uuid),
    CONSTRAINT ck_doctor_schedule_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT ck_doctor_schedule_interval CHECK (start_time < end_time),
    CONSTRAINT ck_doctor_schedule_slot CHECK (slot_minutes > 0),
    CONSTRAINT ck_doctor_schedule_effective_dates CHECK
        (effective_until IS NULL OR effective_until >= effective_from)
);

CREATE INDEX ix_doctor_schedule_lookup
    ON doctor_schedules(hospital_uuid, doctor_uuid, day_of_week, active, effective_from, effective_until);

CREATE TABLE doctor_schedule_exceptions (
    exception_uuid UUID NOT NULL,
    hospital_uuid UUID NOT NULL,
    doctor_uuid UUID NOT NULL,
    exception_date DATE NOT NULL,
    exception_type VARCHAR(16) NOT NULL,
    start_time TIME WITHOUT TIME ZONE,
    end_time TIME WITHOUT TIME ZONE,
    reason VARCHAR(255),
    active BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_doctor_schedule_exceptions PRIMARY KEY (exception_uuid),
    CONSTRAINT uk_doctor_schedule_exception_id_hospital UNIQUE (exception_uuid, hospital_uuid),
    CONSTRAINT fk_doctor_schedule_exception_profile_hospital FOREIGN KEY (doctor_uuid, hospital_uuid)
        REFERENCES doctor_profiles(doctor_uuid, hospital_uuid),
    CONSTRAINT ck_doctor_schedule_exception_type CHECK (exception_type IN ('LEAVE', 'BLOCKED')),
    CONSTRAINT ck_doctor_schedule_exception_interval CHECK (
        (start_time IS NULL AND end_time IS NULL AND exception_type = 'LEAVE')
        OR (start_time IS NOT NULL AND end_time IS NOT NULL AND start_time < end_time)
    )
);

CREATE INDEX ix_doctor_schedule_exception_lookup
    ON doctor_schedule_exceptions(hospital_uuid, doctor_uuid, exception_date, active);
