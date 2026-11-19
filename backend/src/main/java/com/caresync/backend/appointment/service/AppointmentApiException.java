package com.caresync.backend.appointment.service;

import org.springframework.http.HttpStatus;

public class AppointmentApiException extends RuntimeException {
    private final HttpStatus status;

    public AppointmentApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() { return status; }
}
