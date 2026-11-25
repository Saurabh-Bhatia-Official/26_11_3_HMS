package com.caresync.backend.facility.exception;

public class WardAlreadyExistsException extends RuntimeException {

    public WardAlreadyExistsException(String message) {
        super(message);
    }
}