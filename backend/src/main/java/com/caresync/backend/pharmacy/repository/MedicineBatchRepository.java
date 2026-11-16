package com.caresync.backend.pharmacy.repository;

import com.caresync.backend.pharmacy.entity.MedicineBatch;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MedicineBatchRepository extends JpaRepository<MedicineBatch, Long> {
    List<MedicineBatch> findAllByHospitalIdAndDeletedFalse(Long hospitalId);

    List<MedicineBatch> findAllByHospitalIdAndMedicineIdAndDeletedFalseOrderByExpiryDateAsc(
            Long hospitalId, Long medicineId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from MedicineBatch b where b.hospitalId = :hospitalId and b.medicine.id = :medicineId " +
            "and b.deleted = false and b.quantityOnHand > 0 order by b.expiryDate asc, b.id asc")
    List<MedicineBatch> findAvailableForUpdate(@Param("hospitalId") long hospitalId,
                                               @Param("medicineId") long medicineId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from MedicineBatch b where b.id = :id and b.hospitalId = :hospitalId and b.deleted = false")
    Optional<MedicineBatch> findForUpdate(@Param("id") long id, @Param("hospitalId") long hospitalId);

    Optional<MedicineBatch> findByHospitalIdAndMedicineIdAndBatchNoAndDeletedFalse(
            Long hospitalId, Long medicineId, String batchNo);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from MedicineBatch b where b.hospitalId = :hospitalId and b.medicine.id = :medicineId " +
            "and b.batchNo = :batchNo and b.deleted = false")
    Optional<MedicineBatch> findBatchForUpdate(@Param("hospitalId") long hospitalId,
                                                @Param("medicineId") long medicineId,
                                                @Param("batchNo") String batchNo);
}
