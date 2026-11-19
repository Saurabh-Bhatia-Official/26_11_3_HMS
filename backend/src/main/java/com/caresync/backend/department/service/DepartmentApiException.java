package com.caresync.backend.department.service;

import org.springframework.http.HttpStatus;

public class DepartmentApiException extends RuntimeException {
    private final HttpStatus status;

    public DepartmentApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() { return status; }
}
