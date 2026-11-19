package com.caresync.backend.facility.exception;

public class BedNotFoundException extends RuntimeException {

    public BedNotFoundException(Long bedId) {
        super("Bed not found with ID: " + bedId);
    }
}