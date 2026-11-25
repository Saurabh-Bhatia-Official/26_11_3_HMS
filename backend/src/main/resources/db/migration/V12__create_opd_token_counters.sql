
CREATE TABLE IF NOT EXISTS opd_token_counters (
    hospital_uuid UUID NOT NULL,
    doctor_uuid UUID NOT NULL,
    visit_date DATE NOT NULL,
    last_token INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_opd_token_counters
        PRIMARY KEY (hospital_uuid, doctor_uuid, visit_date),

    CONSTRAINT chk_opd_token_counters_last_token
        CHECK (last_token >= 0)
);
