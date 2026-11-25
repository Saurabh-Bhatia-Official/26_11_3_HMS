package com.caresync.backend.patient.service;

import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class PatientApiExceptionHandler {
    @ExceptionHandler(PatientApiException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> patientError(PatientApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }

    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> concurrentUpdate(ObjectOptimisticLockingFailureException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new AuthDtos.ErrorResponse("Patient was changed by another update"));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> integrityConflict(DataIntegrityViolationException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new AuthDtos.ErrorResponse("Patient synchronization conflict"));
    }
}
