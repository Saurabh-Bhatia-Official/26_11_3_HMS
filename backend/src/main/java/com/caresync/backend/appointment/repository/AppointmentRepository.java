package com.caresync.backend.appointment.repository;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.caresync.backend.appointment.entity.Appointment;
import com.caresync.backend.appointment.entity.AppointmentStatus;

import jakarta.persistence.LockModeType;

public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {
    Optional<Appointment> findByIdAndHospital_Id(UUID id, UUID hospitalId);

    @Query("""
            select (count(a) > 0) from Appointment a
            where a.hospital.id = :hospitalId and a.doctor.id = :doctorId
              and a.status <> :cancelled
              and a.startsAt < :end and a.endsAt > :start
              and (:excludedId is null or a.id <> :excludedId)
            """)
    boolean existsOverlappingDoctorAppointment(@Param("hospitalId") UUID hospitalId,
            @Param("doctorId") UUID doctorId, @Param("start") OffsetDateTime start,
            @Param("end") OffsetDateTime end, @Param("cancelled") AppointmentStatus cancelled,
            @Param("excludedId") UUID excludedId);


            @Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("""
        select a from Appointment a
        where a.id = :appointmentId
          and a.hospital.id = :hospitalId
        """)
Optional<Appointment> findByIdAndHospital_IdForUpdate(
        @Param("appointmentId") UUID appointmentId,
        @Param("hospitalId") UUID hospitalId);

        

    @Query("""
            select a from Appointment a
            where a.hospital.id = :hospitalId
              and (:filterDoctor = false or a.doctor.id = :doctorId)
              and (:filterPatient = false or a.patient.uuid = :patientId)
              and (:filterStatus = false or a.status = :status)
              and (:filterFrom = false or a.startsAt >= :fromTime)
              and (:filterUntil = false or a.startsAt < :untilTime)
            """)
    Page<Appointment> searchHospitalAppointments(@Param("hospitalId") UUID hospitalId,
            @Param("filterDoctor") boolean filterDoctor, @Param("doctorId") UUID doctorId,
            @Param("filterPatient") boolean filterPatient, @Param("patientId") UUID patientId,
            @Param("filterStatus") boolean filterStatus, @Param("status") AppointmentStatus status,
            @Param("filterFrom") boolean filterFrom, @Param("fromTime") OffsetDateTime fromTime,
            @Param("filterUntil") boolean filterUntil, @Param("untilTime") OffsetDateTime untilTime,
            Pageable pageable);
}
