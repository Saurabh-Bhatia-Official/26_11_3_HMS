package com.caresync.backend.pharmacy.service;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.pharmacy.dto.PharmacyDtos;
import com.caresync.backend.pharmacy.entity.Dispensing;
import com.caresync.backend.pharmacy.entity.DispensingItem;
import com.caresync.backend.pharmacy.entity.Medicine;
import com.caresync.backend.pharmacy.entity.MedicineBatch;
import com.caresync.backend.pharmacy.entity.StockAdjustment;
import com.caresync.backend.pharmacy.entity.Supplier;
import com.caresync.backend.pharmacy.repository.DispensingRepository;
import com.caresync.backend.pharmacy.repository.MedicineBatchRepository;
import com.caresync.backend.pharmacy.repository.MedicineRepository;
import com.caresync.backend.pharmacy.repository.StockAdjustmentRepository;
import com.caresync.backend.pharmacy.repository.SupplierRepository;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.reference.ReferenceService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class PharmacyService {
    private final AccessContext access;
    private final SupplierRepository suppliers;
    private final MedicineRepository medicines;
    private final MedicineBatchRepository batches;
    private final StockAdjustmentRepository adjustments;
    private final DispensingRepository dispensings;
    private final PatientRepository patients;
    private final ReferenceService references;

    public PharmacyService(AccessContext access, SupplierRepository suppliers, MedicineRepository medicines,
                           MedicineBatchRepository batches, StockAdjustmentRepository adjustments,
                           DispensingRepository dispensings, PatientRepository patients,
                           ReferenceService references) {
        this.access = access;
        this.suppliers = suppliers;
        this.medicines = medicines;
        this.batches = batches;
        this.adjustments = adjustments;
        this.dispensings = dispensings;
        this.patients = patients;
        this.references = references;
    }

    @Transactional(readOnly = true)
    public List<PharmacyDtos.SupplierResponse> suppliers() {
        return suppliers.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(access.hospitalId())
                .stream().map(PharmacyService::supplierResponse).toList();
    }

    public PharmacyDtos.SupplierResponse createSupplier(PharmacyDtos.SupplierRequest request) {
        Supplier supplier = new Supplier(access.hospitalId(), request.name().trim(), request.contactPerson(),
                request.phone(), request.email(), request.address(), request.gstNo());
        return supplierResponse(suppliers.save(supplier));
    }

    public PharmacyDtos.SupplierResponse updateSupplier(long id, PharmacyDtos.SupplierRequest request) {
        Supplier supplier = suppliers.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Supplier"));
        supplier.update(request.name().trim(), request.contactPerson(), request.phone(), request.email(),
                request.address(), request.gstNo());
        return supplierResponse(supplier);
    }

    @Transactional(readOnly = true)
    public List<PharmacyDtos.MedicineResponse> medicines() {
        long hospitalId = access.hospitalId();
        return medicines.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(hospitalId)
                .stream().map(medicine -> medicineResponse(medicine, stockFor(hospitalId, medicine.getId()))).toList();
    }

    public PharmacyDtos.MedicineResponse createMedicine(PharmacyDtos.MedicineRequest request) {
        Medicine medicine = new Medicine(access.hospitalId(), request.name().trim(), request.genericName(),
                request.form(), request.strength(), request.manufacturer(), request.category(), request.unit(),
                request.taxRatePct(), request.reorderLevel(), request.hsnCode());
        return medicineResponse(medicines.save(medicine), 0);
    }

    public PharmacyDtos.MedicineResponse updateMedicine(long id, PharmacyDtos.MedicineRequest request) {
        Medicine medicine = findMedicine(id);
        medicine.update(request.name().trim(), request.genericName(), request.form(), request.strength(),
                request.manufacturer(), request.category(), request.unit(), request.taxRatePct(),
                request.reorderLevel(), request.hsnCode());
        return medicineResponse(medicine, stockFor(access.hospitalId(), id));
    }

    public void deleteMedicine(long id) { findMedicine(id).markDeleted(); }

    @Transactional(readOnly = true)
    public List<PharmacyDtos.BatchResponse> batches(long medicineId) {
        findMedicine(medicineId);
        return batches.findAllByHospitalIdAndMedicineIdAndDeletedFalseOrderByExpiryDateAsc(access.hospitalId(), medicineId)
                .stream().map(PharmacyService::batchResponse).toList();
    }

    public PharmacyDtos.BatchResponse receive(PharmacyDtos.ReceiveStockRequest request) {
        long hospitalId = access.hospitalId();
        if (request.quantity() <= 0 || request.purchasePricePaise() < 0 || request.mrpPaise() < 0) {
            throw BusinessException.invalid("Stock quantity must be positive and prices cannot be negative");
        }
        Medicine medicine = findMedicine(request.medicineId());
        if (!request.expiryDate().isAfter(LocalDate.now(ZoneOffset.UTC))) {
            throw BusinessException.invalid("Cannot receive an expired or expiring-today batch");
        }
        Supplier supplier = request.supplierId() == null ? null : suppliers
                .findByIdAndHospitalIdAndDeletedFalse(request.supplierId(), hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Supplier"));
        MedicineBatch batch = batches.findBatchForUpdate(hospitalId, medicine.getId(), request.batchNo().trim())
                .orElse(null);
        if (batch == null) {
            batch = new MedicineBatch(hospitalId, medicine, request.batchNo().trim(), request.expiryDate(),
                    request.manufactureDate(), request.quantity(), request.purchasePricePaise(), request.mrpPaise(), supplier);
        } else {
            if (!batch.getExpiryDate().equals(request.expiryDate())) {
                throw BusinessException.conflict("Batch expiry does not match the existing batch");
            }
            batch.receive(request.quantity(), request.purchasePricePaise(), request.mrpPaise());
        }
        return batchResponse(batches.save(batch));
    }

    public PharmacyDtos.AdjustmentResponse adjust(PharmacyDtos.AdjustmentRequest request) {
        if (request.adjustmentQuantity() == 0) throw BusinessException.invalid("Adjustment quantity cannot be zero");
        MedicineBatch batch = batches.findForUpdate(request.batchId(), access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Medicine batch"));
        try {
            batch.adjust(request.adjustmentQuantity());
        } catch (IllegalArgumentException | ArithmeticException exception) {
            throw BusinessException.conflict("Stock adjustment would make inventory invalid");
        }
        StockAdjustment adjustment = adjustments.save(new StockAdjustment(access.hospitalId(), batch,
                request.adjustmentQuantity(), request.reason().trim(), access.userId()));
        return adjustmentResponse(adjustment);
    }

    @Transactional(readOnly = true)
    public List<PharmacyDtos.AdjustmentResponse> adjustments() {
        return adjustments.findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(access.hospitalId())
                .stream().map(PharmacyService::adjustmentResponse).toList();
    }

    public PharmacyDtos.DispensingResponse dispense(PharmacyDtos.DispenseRequest request) {
        long hospitalId = access.hospitalId();
        if (request.patientId() <= 0 || request.prescriptionId() != null && request.prescriptionId() <= 0
                || request.visitId() != null && request.visitId() <= 0) {
            throw BusinessException.invalid("Patient, prescription, and visit identifiers must be positive");
        }
        PatientRecord patient = patients.findByIdAndHospitalIdAndDeletedFalse(request.patientId(), hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Patient"));
        Long visitId = references.resolveVisitId(request.visitId(), request.visitUuid(), patient.getId());
        Long prescriptionId = references.resolvePrescriptionId(request.prescriptionId(), request.prescriptionUuid(),
                patient.getId(), visitId, null);
        if (request.items() == null || request.items().isEmpty()) {
            throw BusinessException.invalid("A dispensing must contain at least one item");
        }
        Set<Long> medicineIds = new HashSet<>();
        for (PharmacyDtos.DispensingItemRequest item : request.items()) {
            if (item == null || item.medicineId() <= 0 || item.quantity() <= 0 || item.quantity() > 1_000_000) {
                throw BusinessException.invalid("Medicine identifiers and dispensing quantities must be positive");
            }
            if (!medicineIds.add(item.medicineId())) {
                throw BusinessException.invalid("A medicine can only appear once in a dispensing request");
            }
        }

        List<DispensedLine> lines = request.items().stream()
                .flatMap(item -> allocate(hospitalId, item).stream()).toList();
        long total;
        try {
            total = lines.stream().mapToLong(DispensedLine::totalPaise).reduce(0, Math::addExact);
        } catch (ArithmeticException exception) {
            throw BusinessException.invalid("Dispensing total exceeds the supported amount");
        }
        if (total < 0) throw BusinessException.invalid("Dispensing total cannot be negative");
        Dispensing dispensing = new Dispensing(hospitalId, request.patientId(), prescriptionId,
                visitId, access.userId(), Boolean.TRUE.equals(request.counterSale()), total);
        for (DispensedLine line : lines) {
            dispensing.addItem(new DispensingItem(line.medicine(), line.batch(), line.quantity(),
                    line.unitPricePaise(), line.taxRatePct(), line.totalPaise()));
        }
        return dispensingResponse(dispensings.save(dispensing));
    }

    @Transactional(readOnly = true)
    public List<PharmacyDtos.DispensingResponse> dispensings() {
        return dispensings.findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(access.hospitalId())
                .stream().map(PharmacyService::dispensingResponse).toList();
    }

    private List<DispensedLine> allocate(long hospitalId, PharmacyDtos.DispensingItemRequest requested) {
        Medicine medicine = findMedicine(requested.medicineId());
        int remaining = requested.quantity();
        List<DispensedLine> allocations = new java.util.ArrayList<>();
        List<MedicineBatch> available = batches.findAvailableForUpdate(hospitalId, medicine.getId());
        for (MedicineBatch batch : available) {
            if (!batch.isUnexpiredOn(LocalDate.now(ZoneOffset.UTC))) continue;
            int allocated = Math.min(remaining, batch.getQuantityOnHand());
            if (allocated == 0) continue;
            int updated = batches.decrementStockIfAvailable(batch.getId(), hospitalId, allocated,
                    LocalDate.now(ZoneOffset.UTC));
            if (updated != 1) {
                throw BusinessException.conflict("Stock changed while dispensing; retry the request");
            }
            try {
                long base = Math.multiplyExact(batch.getMrpPaise(), allocated);
                long tax = percent(base, medicine.getTaxRatePct());
                allocations.add(new DispensedLine(medicine, batch, allocated, batch.getMrpPaise(),
                        medicine.getTaxRatePct(), Math.addExact(base, tax)));
            } catch (ArithmeticException exception) {
                throw BusinessException.invalid("Dispensing amount exceeds the supported range");
            }
            remaining -= allocated;
            if (remaining == 0) break;
        }
        if (remaining > 0) throw BusinessException.conflict("Insufficient unexpired stock for " + medicine.getName());
        return allocations;
    }

    private int stockFor(long hospitalId, long medicineId) {
        return batches.findAllByHospitalIdAndMedicineIdAndDeletedFalseOrderByExpiryDateAsc(hospitalId, medicineId)
                .stream().filter(batch -> batch.isUnexpiredOn(LocalDate.now(ZoneOffset.UTC)))
                .mapToInt(MedicineBatch::getQuantityOnHand).sum();
    }

    private Medicine findMedicine(long id) {
        return medicines.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Medicine"));
    }

    private static long percent(long amount, double percentage) {
        return BigDecimal.valueOf(amount).multiply(BigDecimal.valueOf(percentage))
                .divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP).longValueExact();
    }

    private static PharmacyDtos.SupplierResponse supplierResponse(Supplier supplier) {
        return new PharmacyDtos.SupplierResponse(supplier.getId(), supplier.getUuid(), supplier.getName(),
                supplier.getContactPerson(), supplier.getPhone(), supplier.getEmail(), supplier.getAddress(),
                supplier.getGstNo(), supplier.getCreatedAt(), supplier.getUpdatedAt());
    }

    private static PharmacyDtos.MedicineResponse medicineResponse(Medicine medicine, int stock) {
        return new PharmacyDtos.MedicineResponse(medicine.getId(), medicine.getUuid(), medicine.getName(),
                medicine.getGenericName(), medicine.getForm(), medicine.getStrength(), medicine.getManufacturer(),
                medicine.getCategory(), medicine.getUnit(), medicine.getTaxRatePct(), medicine.getReorderLevel(),
                medicine.getHsnCode(), stock, medicine.getCreatedAt(), medicine.getUpdatedAt());
    }

    private static PharmacyDtos.BatchResponse batchResponse(MedicineBatch batch) {
        return new PharmacyDtos.BatchResponse(batch.getId(), batch.getMedicine().getId(),
                batch.getMedicine().getName(), batch.getBatchNo(), batch.getExpiryDate(), batch.getManufactureDate(),
                batch.getQuantityOnHand(), batch.getPurchasePricePaise(), batch.getMrpPaise(),
                batch.getSupplier() == null ? null : batch.getSupplier().getId(), batch.getUpdatedAt());
    }

    private static PharmacyDtos.AdjustmentResponse adjustmentResponse(StockAdjustment adjustment) {
        return new PharmacyDtos.AdjustmentResponse(adjustment.getId(), adjustment.getBatch().getId(),
                adjustment.getBatch().getMedicine().getName(), adjustment.getBatch().getBatchNo(),
                adjustment.getAdjustmentQuantity(), adjustment.getReason(), adjustment.getAdjustedBy(),
                adjustment.getCreatedAt());
    }

    private static PharmacyDtos.DispensingResponse dispensingResponse(Dispensing dispensing) {
        List<PharmacyDtos.DispensingItemResponse> items = dispensing.getItems().stream()
                .map(item -> new PharmacyDtos.DispensingItemResponse(item.getMedicine().getId(),
                        item.getMedicine().getName(), item.getBatch().getId(), item.getBatch().getBatchNo(),
                        item.getQuantity(), item.getUnitPricePaise(), item.getTaxRatePct(), item.getTotalPaise()))
                .toList();
        return new PharmacyDtos.DispensingResponse(dispensing.getId(), dispensing.getPatientId(),
                dispensing.getPrescriptionId(), dispensing.getVisitId(), dispensing.getDispensedBy(),
                dispensing.isCounterSale(), dispensing.getTotalAmountPaise(), dispensing.getCreatedAt(), items);
    }

    private record DispensedLine(Medicine medicine, MedicineBatch batch, int quantity, long unitPricePaise,
                                 double taxRatePct, long totalPaise) {}
}
