package com.caresync.backend.appointment.repository;

import com.caresync.backend.appointment.entity.AppointmentEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AppointmentEventRepository extends JpaRepository<AppointmentEvent, UUID> {
    List<AppointmentEvent> findAllByAppointment_IdAndHospitalUuidOrderByOccurredAtAsc(
            UUID appointmentId, UUID hospitalUuid);
}
