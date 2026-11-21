package com.caresync.backend.security;

import jakarta.validation.ConstraintViolationException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import tools.jackson.databind.ObjectMapper;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ApiExceptionHandlerTests {
    private final ApiExceptionHandler handler = new ApiExceptionHandler();

    @Test
    void validationFailuresUseExistingGenericAuthenticationErrorShape() {
        var response = handler.validation(new ConstraintViolationException("sensitive detail", Set.of()));

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("Invalid request", response.getBody().error());
    }

    @Test
    void validationErrorJsonKeepsTheExistingSingleErrorField() throws Exception {
        var response = handler.validation(new ConstraintViolationException("sensitive detail", Set.of()));

        assertEquals("{\"error\":\"Invalid request\"}", new ObjectMapper().writeValueAsString(response.getBody()));
    }

    @Test
    void unexpectedErrorsDoNotExposeInternalMessages() {
        var response = handler.unexpected(new IllegalStateException("database password leaked"));

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals("Request could not be completed", response.getBody().error());
    }
}
