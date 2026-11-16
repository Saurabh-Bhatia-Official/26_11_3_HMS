package com.caresync.backend.common.response;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ApiResponseTests {
    @Test
    void holdsResponseDataWithoutMutabilityHelpers() {
        ApiResponse<String> response = ApiResponse.of("value");

        assertEquals("value", response.data());
    }
}
