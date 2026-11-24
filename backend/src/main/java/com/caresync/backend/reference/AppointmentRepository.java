package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AppointmentRepository extends JpaRepository<AppointmentRecord, Long> {
    List<AppointmentRecord> findAllByHospitalIdAndDeletedFalseOrderByAppointmentDateDesc(Long hospitalId);
    Optional<AppointmentRecord> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
    Optional<AppointmentRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, Long hospitalId);

    @Query("select count(a) from AppointmentRecord a where a.hospitalId = :hospitalId " +
            "and a.deleted = false and a.appointmentDate = :date and lower(a.status) <> 'cancelled'")
    long countAppointmentsByDate(@Param("hospitalId") long hospitalId, @Param("date") LocalDate date);
}
