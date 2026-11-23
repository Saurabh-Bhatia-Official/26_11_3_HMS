package com.caresync.backend.billing.service;

import com.caresync.backend.billing.dto.BillingDtos;
import com.caresync.backend.billing.repository.BillableServiceRepository;
import com.caresync.backend.billing.repository.InvoiceRepository;
import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.reference.ReferenceService;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class BillingServiceTests {
    @Test
    void rejectsNonpositivePaymentBeforeLoadingInvoice() {
        AccessContext access = mock(AccessContext.class);
        BillableServiceRepository services = mock(BillableServiceRepository.class);
        InvoiceRepository invoices = mock(InvoiceRepository.class);
        PatientRepository patients = mock(PatientRepository.class);
        ReferenceService references = mock(ReferenceService.class);
        BillingService billing = new BillingService(access, services, invoices, patients, references);

        BusinessException exception = assertThrows(BusinessException.class,
                () -> billing.addPayment(1L, new BillingDtos.PaymentRequest("cash", 0, null)));

        assertEquals(400, exception.getStatus().value());
        verifyNoInteractions(invoices);
    }
}
