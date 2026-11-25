package com.caresync.backend.doctor.dto;

import com.caresync.backend.doctor.entity.DoctorScheduleException;
import com.caresync.backend.doctor.entity.ScheduleExceptionType;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record DoctorScheduleExceptionResponse(UUID id, UUID doctorId, LocalDate date,
                                              ScheduleExceptionType type, LocalTime startTime,
                                              LocalTime endTime, String reason, boolean active,
                                              Instant createdAt, Instant updatedAt) {
    public static DoctorScheduleExceptionResponse from(DoctorScheduleException exception) {
        return new DoctorScheduleExceptionResponse(exception.getId(), exception.getDoctor().getId(),
                exception.getDate(), exception.getType(), exception.getStartTime(), exception.getEndTime(),
                exception.getReason(), exception.isActive(), exception.getCreatedAt(), exception.getUpdatedAt());
    }
}
