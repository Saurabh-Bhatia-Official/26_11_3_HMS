package com.caresync.backend.common.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PaginationRequestTests {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void defaultsMissingValuesAndCalculatesOffset() {
        PaginationRequest request = new PaginationRequest(null, null);

        assertEquals(0, request.page());
        assertEquals(20, request.size());
        assertEquals(0L, request.offset());
        assertEquals(60L, new PaginationRequest(3, 20).offset());
    }

    @Test
    void acceptsBoundaryValuesAndRejectsInvalidPageOrSize() {
        assertTrue(validator.validate(new PaginationRequest(0, 1)).isEmpty());
        assertTrue(validator.validate(new PaginationRequest(10, 100)).isEmpty());
        assertFalse(validator.validate(new PaginationRequest(-1, 20)).isEmpty());
        assertFalse(validator.validate(new PaginationRequest(0, 0)).isEmpty());
        assertFalse(validator.validate(new PaginationRequest(0, 101)).isEmpty());
    }
}
