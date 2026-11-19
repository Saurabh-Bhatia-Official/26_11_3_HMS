
package com.caresync.backend.facility.exception;

public class RoomNotFoundException extends RuntimeException {

    public RoomNotFoundException(Long roomId) {
        super("Room not found with ID: " + roomId);
    }
}
