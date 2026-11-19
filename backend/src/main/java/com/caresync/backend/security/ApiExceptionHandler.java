
package com.caresync.backend.security;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import com.caresync.backend.facility.exception.BedAlreadyExistsException;
import com.caresync.backend.facility.exception.BedNotFoundException;
import com.caresync.backend.facility.exception.RoomAlreadyExistsException;
import com.caresync.backend.facility.exception.RoomNotFoundException;
import com.caresync.backend.facility.exception.WardAlreadyExistsException;
import com.caresync.backend.facility.exception.WardNotFoundException;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> validation(
            MethodArgumentNotValidException exception) {
        return ResponseEntity.badRequest()
                .body(new AuthDtos.ErrorResponse("Invalid request"));
    }

    @ExceptionHandler(WardNotFoundException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> wardNotFound(
            WardNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new AuthDtos.ErrorResponse("Ward not found"));
    }

    @ExceptionHandler(WardAlreadyExistsException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> wardAlreadyExists(
            WardAlreadyExistsException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new AuthDtos.ErrorResponse(
                        "A ward with this code already exists"));
    }

    @ExceptionHandler(RoomNotFoundException.class)
public ResponseEntity<AuthDtos.ErrorResponse> roomNotFound(
        RoomNotFoundException exception) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new AuthDtos.ErrorResponse("Room not found"));
}

@ExceptionHandler(RoomAlreadyExistsException.class)
public ResponseEntity<AuthDtos.ErrorResponse> roomAlreadyExists(
        RoomAlreadyExistsException exception) {
    return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(new AuthDtos.ErrorResponse(exception.getMessage()));
}

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unreadableRequest(
            HttpMessageNotReadableException exception) {
        return ResponseEntity.badRequest()
                .body(new AuthDtos.ErrorResponse("Invalid request"));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unsupportedMethod(
            HttpRequestMethodNotSupportedException exception) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(new AuthDtos.ErrorResponse("Method not allowed"));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unsupportedMediaType(
            HttpMediaTypeNotSupportedException exception) {
        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE)
                .body(new AuthDtos.ErrorResponse("Unsupported media type"));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> responseStatus(
            ResponseStatusException exception) {
        return ResponseEntity.status(exception.getStatusCode())
                .body(new AuthDtos.ErrorResponse(
                        exception.getReason() != null
                                ? exception.getReason()
                                : "Request could not be completed"
                ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unexpected(
            Exception exception) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthDtos.ErrorResponse(
                        "Request could not be completed"));
    }

    @ExceptionHandler(BedNotFoundException.class)
public ResponseEntity<AuthDtos.ErrorResponse> bedNotFound(
        BedNotFoundException exception
) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new AuthDtos.ErrorResponse("Bed not found"));
}

@ExceptionHandler(BedAlreadyExistsException.class)
public ResponseEntity<AuthDtos.ErrorResponse> bedAlreadyExists(
        BedAlreadyExistsException exception
) {
    return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(new AuthDtos.ErrorResponse(exception.getMessage()));
}
}
