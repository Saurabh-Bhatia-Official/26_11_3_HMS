package com.caresync.backend.membership.controller;

import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice(assignableTypes = MembershipController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MembershipApiExceptionHandler {
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> status(ResponseStatusException exception) {
        String message = exception.getReason() == null ? "Membership request was rejected" : exception.getReason();
        return ResponseEntity.status(exception.getStatusCode()).body(new AuthDtos.ErrorResponse(message));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> conflict(DataIntegrityViolationException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new AuthDtos.ErrorResponse("Membership conflicts with existing account or hospital data"));
    }
}
