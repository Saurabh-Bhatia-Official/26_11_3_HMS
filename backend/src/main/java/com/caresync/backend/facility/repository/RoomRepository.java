
package com.caresync.backend.facility.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.caresync.backend.facility.entity.Room;

public interface RoomRepository extends JpaRepository<Room, Long> {

    List<Room> findAllByHospitalId(Long hospitalId);

    List<Room> findAllByHospitalIdAndWard_Id(
            Long hospitalId,
            Long wardId
    );

    Optional<Room> findByIdAndHospitalId(
            Long id,
            Long hospitalId
    );

    boolean existsByWard_IdAndRoomNumber(
            Long wardId,
            String roomNumber
    );

    boolean existsByWard_IdAndRoomNumberAndIdNot(
            Long wardId,
            String roomNumber,
            Long id
    );
}
