package com.caresync.backend.facility.exception;

public class BedAlreadyExistsException extends RuntimeException {

    public BedAlreadyExistsException(String bedNo) {
        super("Bed number already exists in this room: " + bedNo);
    }
}