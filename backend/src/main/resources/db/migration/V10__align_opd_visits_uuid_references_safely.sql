-- V10: Add UUID-based OPD references without replacing legacy numeric IDs.
-- Forward-only and data-preserving. Existing numeric columns remain available.
-- New application writes must populate hospital_uuid and doctor_uuid.

-- 1. Add modern UUID references alongside the legacy BIGINT references.
ALTER TABLE public.opd_visits
    ADD COLUMN IF NOT EXISTS hospital_uuid UUID,
    ADD COLUMN IF NOT EXISTS doctor_uuid UUID,
    ADD COLUMN IF NOT EXISTS department_uuid UUID,
    ADD COLUMN IF NOT EXISTS appointment_uuid UUID;

-- New UUID-based visit creation does not have legacy numeric doctor/department/
-- appointment IDs. Keep those columns, but allow them to be NULL for new rows.
ALTER TABLE public.opd_visits
    ALTER COLUMN doctor_id DROP NOT NULL,
    ALTER COLUMN department_id DROP NOT NULL,
    ALTER COLUMN appointment_id DROP NOT NULL;

-- 2. Ensure PostgreSQL has an exact unique key for the patient/hospital composite FK.
-- patient_id is already the primary key; this index does not change patient data.
CREATE UNIQUE INDEX IF NOT EXISTS ux_patients_patient_id_hospital_uuid
    ON public.patients (patient_id, hospital_uuid);

-- 3. Add tenant-aware foreign keys. NOT VALID preserves any legacy rows that do
-- not yet have UUID references, while enforcing the constraints for new writes.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_opd_visit_hospital_uuid'
          AND conrelid = 'public.opd_visits'::regclass
    ) THEN
        ALTER TABLE public.opd_visits
            ADD CONSTRAINT fk_opd_visit_hospital_uuid
            FOREIGN KEY (hospital_uuid)
            REFERENCES public.hospitals (hospital_uuid)
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_opd_visit_patient_hospital_uuid'
          AND conrelid = 'public.opd_visits'::regclass
    ) THEN
        ALTER TABLE public.opd_visits
            ADD CONSTRAINT fk_opd_visit_patient_hospital_uuid
            FOREIGN KEY (patient_id, hospital_uuid)
            REFERENCES public.patients (patient_id, hospital_uuid)
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_opd_visit_doctor_hospital_uuid'
          AND conrelid = 'public.opd_visits'::regclass
    ) THEN
        ALTER TABLE public.opd_visits
            ADD CONSTRAINT fk_opd_visit_doctor_hospital_uuid
            FOREIGN KEY (doctor_uuid, hospital_uuid)
            REFERENCES public.doctor_profiles (doctor_uuid, hospital_uuid)
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_opd_visit_department_hospital_uuid'
          AND conrelid = 'public.opd_visits'::regclass
    ) THEN
        ALTER TABLE public.opd_visits
            ADD CONSTRAINT fk_opd_visit_department_hospital_uuid
            FOREIGN KEY (department_uuid, hospital_uuid)
            REFERENCES public.departments (department_uuid, hospital_uuid)
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_opd_visit_appointment_hospital_uuid'
          AND conrelid = 'public.opd_visits'::regclass
    ) THEN
        ALTER TABLE public.opd_visits
            ADD CONSTRAINT fk_opd_visit_appointment_hospital_uuid
            FOREIGN KEY (appointment_uuid, hospital_uuid)
            REFERENCES public.appointments (appointment_uuid, hospital_uuid)
            NOT VALID;
    END IF;
END $$;

-- 4. UUID appointment idempotency. NULL appointment_uuid remains valid for walk-ins.
CREATE UNIQUE INDEX IF NOT EXISTS ux_opd_visit_hospital_uuid_appointment_uuid
    ON public.opd_visits (hospital_uuid, appointment_uuid)
    WHERE appointment_uuid IS NOT NULL;

-- 5. Prevent duplicate queue tokens per hospital, doctor, and date.
CREATE UNIQUE INDEX IF NOT EXISTS ux_opd_visit_hospital_doctor_date_token
    ON public.opd_visits (hospital_uuid, doctor_uuid, visit_date, token_no)