package com.caresync.backend.appointment.dto;

import com.caresync.backend.appointment.entity.Appointment;
import com.caresync.backend.appointment.entity.AppointmentStatus;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.UUID;

public record AppointmentResponse(UUID appointmentUuid, UUID patientUuid, String patientUhid, String patientName,
                                  UUID doctorUuid, String doctorName, UUID departmentUuid,
                                  OffsetDateTime startsAt, OffsetDateTime endsAt, String appointmentType,
                                  String reason, String notes, AppointmentStatus status,
                                  Instant createdAt, Instant updatedAt) {
    public static AppointmentResponse from(Appointment appointment) {
        ZoneId hospitalZone = ZoneId.of(appointment.getHospital().getTimeZone());
        return new AppointmentResponse(appointment.getId(), appointment.getPatient().getUuid(),
                appointment.getPatient().getUhid(), appointment.getPatient().getName(),
                appointment.getDoctor().getId(), appointment.getDoctor().getMembership().getAccount().getFullName(),
                appointment.getDepartment() == null ? null : appointment.getDepartment().getId(),
                appointment.getStartsAt().atZoneSameInstant(hospitalZone).toOffsetDateTime(),
                appointment.getEndsAt().atZoneSameInstant(hospitalZone).toOffsetDateTime(), appointment.getAppointmentType(),
                appointment.getReason(), appointment.getNotes(), appointment.getStatus(),
                appointment.getCreatedAt(), appointment.getUpdatedAt());
    }
}
