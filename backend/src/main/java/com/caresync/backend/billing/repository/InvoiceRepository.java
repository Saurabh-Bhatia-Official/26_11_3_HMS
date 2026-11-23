package com.caresync.backend.billing.repository;

import com.caresync.backend.billing.entity.Invoice;
import com.caresync.backend.billing.entity.Payment;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
    List<Invoice> findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(Long hospitalId);
    Optional<Invoice> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select i from Invoice i where i.id = :id and i.hospitalId = :hospitalId and i.deleted = false")
    Optional<Invoice> findForUpdate(@Param("id") long id, @Param("hospitalId") long hospitalId);

    long countByHospitalIdAndDeletedFalseAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
            Long hospitalId, Instant start, Instant end);

    @Query("select coalesce(sum(i.paidPaise), 0) from Invoice i where i.hospitalId = :hospitalId " +
            "and i.deleted = false and lower(i.status) <> 'cancelled' and i.createdAt >= :start and i.createdAt < :end")
    Long sumPaymentsByDate(@Param("hospitalId") long hospitalId, @Param("start") Instant start,
                           @Param("end") Instant end);

    @Query("select coalesce(sum(i.duePaise), 0) from Invoice i where i.hospitalId = :hospitalId " +
            "and i.deleted = false and lower(i.status) <> 'cancelled'")
    Long sumCurrentOutstanding(@Param("hospitalId") long hospitalId);

    @Query("select p from Payment p where p.invoice.hospitalId = :hospitalId and p.invoice.deleted = false " +
            "and lower(p.invoice.status) <> 'cancelled' and p.paidAt >= :start and p.paidAt < :end order by p.paidAt asc")
    List<Payment> paymentsBetween(@Param("hospitalId") long hospitalId, @Param("start") Instant start,
                                  @Param("end") Instant end);

    @Query("select coalesce(sum(p.amountPaise), 0) from Payment p where p.invoice.hospitalId = :hospitalId " +
            "and p.invoice.deleted = false and lower(p.invoice.status) <> 'cancelled' and p.paidAt >= :start and p.paidAt < :end")
    Long sumCompletedPaymentsBetween(@Param("hospitalId") long hospitalId, @Param("start") Instant start,
                                     @Param("end") Instant end);
}
