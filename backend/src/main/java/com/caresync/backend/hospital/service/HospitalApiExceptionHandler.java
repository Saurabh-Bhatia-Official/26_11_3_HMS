package com.caresync.backend.hospital.service;

import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class HospitalApiExceptionHandler {
    @ExceptionHandler(HospitalApiException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> handle(HospitalApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }
}
