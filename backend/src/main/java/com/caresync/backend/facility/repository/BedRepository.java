package com.caresync.backend.facility.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.caresync.backend.facility.entity.Bed;
import com.caresync.backend.facility.entity.BedStatus;

@Repository
public interface BedRepository extends JpaRepository<Bed, Long> {

    @Query("""
        SELECT b
        FROM Bed b
        JOIN b.room r
        JOIN r.ward w
        WHERE b.hospitalId = :hospitalId
          AND (:roomId IS NULL OR r.id = :roomId)
          AND (:wardId IS NULL OR w.id = :wardId)
          AND (:status IS NULL OR b.status = :status)
        ORDER BY b.id DESC
    """)
    List<Bed> findBeds(
            @Param("hospitalId") Long hospitalId,
            @Param("roomId") Long roomId,
            @Param("wardId") Long wardId,
            @Param("status") BedStatus status
    );

    Optional<Bed> findByIdAndHospitalId(Long id, Long hospitalId);

    boolean existsByRoom_IdAndBedNo(Long roomId, String bedNo);

    boolean existsByRoom_IdAndBedNoAndIdNot(
            Long roomId,
            String bedNo,
            Long bedId
    );
}