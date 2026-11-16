package com.caresync.backend.hospital.service;

import org.springframework.http.HttpStatus;

public final class HospitalApiException extends RuntimeException {
    private final HttpStatus status;

    public HospitalApiException(HttpStatus status, String safeMessage) {
        super(safeMessage);
        this.status = status;
    }

    public HttpStatus getStatus() { return status; }
}
