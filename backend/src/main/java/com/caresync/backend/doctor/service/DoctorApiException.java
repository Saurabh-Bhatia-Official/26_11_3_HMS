package com.caresync.backend.doctor.service;

import org.springframework.http.HttpStatus;

public class DoctorApiException extends RuntimeException {
    private final HttpStatus status;

    public DoctorApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() { return status; }
}
