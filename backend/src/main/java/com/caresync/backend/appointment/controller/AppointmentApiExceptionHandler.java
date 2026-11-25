package com.caresync.backend.appointment.controller;

import com.caresync.backend.appointment.service.AppointmentApiException;
import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = AppointmentController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AppointmentApiExceptionHandler {
    @ExceptionHandler(AppointmentApiException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> appointmentError(AppointmentApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }
}
