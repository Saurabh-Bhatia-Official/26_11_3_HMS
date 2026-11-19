package com.caresync.backend.doctor.repository;

import com.caresync.backend.doctor.entity.DoctorSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DoctorScheduleRepository extends JpaRepository<DoctorSchedule, UUID> {
    List<DoctorSchedule> findAllByDoctor_IdAndHospital_IdOrderByDayOfWeekAscStartTimeAsc(
            UUID doctorId, UUID hospitalId);

    List<DoctorSchedule> findAllByDoctor_IdAndHospital_IdAndActiveTrueAndDayOfWeekAndEffectiveFromLessThanEqual(
            UUID doctorId, UUID hospitalId, int dayOfWeek, LocalDate date);

    Optional<DoctorSchedule> findByIdAndDoctor_IdAndHospital_Id(UUID id, UUID doctorId, UUID hospitalId);
}
