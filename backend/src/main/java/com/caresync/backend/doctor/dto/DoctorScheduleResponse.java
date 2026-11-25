package com.caresync.backend.doctor.dto;

import com.caresync.backend.doctor.entity.DoctorSchedule;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record DoctorScheduleResponse(UUID id, UUID doctorId, int dayOfWeek, LocalTime startTime,
                                     LocalTime endTime, int slotMinutes, LocalDate effectiveFrom,
                                     LocalDate effectiveUntil, boolean active, Instant createdAt,
                                     Instant updatedAt) {
    public static DoctorScheduleResponse from(DoctorSchedule schedule) {
        return new DoctorScheduleResponse(schedule.getId(), schedule.getDoctor().getId(),
                schedule.getDayOfWeek(), schedule.getStartTime(), schedule.getEndTime(),
                schedule.getSlotMinutes(), schedule.getEffectiveFrom(), schedule.getEffectiveUntil(),
                schedule.isActive(), schedule.getCreatedAt(), schedule.getUpdatedAt());
    }
}
