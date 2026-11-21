package com.caresync.backend.patient.service;

import org.springframework.http.HttpStatus;

public final class PatientApiException extends RuntimeException {
    private final HttpStatus status;

    public PatientApiException(HttpStatus status, String safeMessage) {
        super(safeMessage);
        this.status = status;
    }

    public HttpStatus getStatus() { return status; }
}
