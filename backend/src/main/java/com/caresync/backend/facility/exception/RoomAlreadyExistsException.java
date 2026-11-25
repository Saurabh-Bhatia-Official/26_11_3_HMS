
package com.caresync.backend.facility.exception;

public class RoomAlreadyExistsException extends RuntimeException {

    public RoomAlreadyExistsException(String roomNumber, Long wardId) {
        super("Room number '" + roomNumber
                + "' already exists in Ward ID: " + wardId);
    }
}
