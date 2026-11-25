package com.caresync.backend.staff.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class StaffCreateRequestTests {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void requiresNameAndRole() {
        var violations = validator.validate(new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", " ", "", null, null,
                null, null, null, null, null));

        assertEquals(2, violations.size());
    }

    @Test
    void requiresClientCorrelationUuid() {
        var violations = validator.validate(new StaffCreateRequest(
                "", "Asha Rao", "Nurse", null, null, null, null, null, null, null));

        assertTrue(violations.stream().anyMatch(violation ->
                violation.getPropertyPath().toString().equals("uuid")));
    }

    @Test
    void rejectsMalformedUuidEmailAndPhone() {
        var violations = validator.validate(new StaffCreateRequest(
                "not-a-uuid", "Asha Rao", "Nurse", null, null,
                "123", "not-an-email", null, null, null));

        assertEquals(3, violations.size());
    }

    @Test
    void acceptsRequiredFieldsAndOptionalOfflineProfileFields() {
        var request = new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", "Asha Rao", "Nurse", "EMP-12", "Emergency", null, null,
                null, "Active", "BSc Nursing");

        assertTrue(validator.validate(request).isEmpty());
    }

    @Test
    void acceptsValidOptionalEmailAndPhoneAndNormalizesBlankValues() {
        var request = new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", "Asha Rao", "Nurse", null, null,
                "+91 (98765) 43210", "asha@example.org", null, null, null);

        assertTrue(validator.validate(request).isEmpty());
        var blankOptionalFields = new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", "Asha Rao", "Nurse", null, null,
                " ", "", null, null, null);
        assertTrue(blankOptionalFields.phone() == null && blankOptionalFields.email() == null);
        assertTrue(validator.validate(blankOptionalFields).isEmpty());
    }
}
