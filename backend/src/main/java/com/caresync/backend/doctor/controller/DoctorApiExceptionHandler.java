package com.caresync.backend.doctor.controller;

import com.caresync.backend.doctor.service.DoctorApiException;
import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = DoctorController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class DoctorApiExceptionHandler {
    @ExceptionHandler(DoctorApiException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> doctorError(DoctorApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }
}
