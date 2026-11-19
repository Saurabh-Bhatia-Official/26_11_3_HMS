package com.caresync.backend.doctor.repository;

import com.caresync.backend.doctor.entity.DoctorScheduleException;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DoctorScheduleExceptionRepository extends JpaRepository<DoctorScheduleException, UUID> {
    List<DoctorScheduleException> findAllByDoctor_IdAndHospital_IdAndDateAndActiveTrueOrderByStartTimeAsc(
            UUID doctorId, UUID hospitalId, LocalDate date);

    List<DoctorScheduleException> findAllByDoctor_IdAndHospital_IdOrderByDateAscStartTimeAsc(
            UUID doctorId, UUID hospitalId);

    Optional<DoctorScheduleException> findByIdAndDoctor_IdAndHospital_Id(
            UUID id, UUID doctorId, UUID hospitalId);
}
