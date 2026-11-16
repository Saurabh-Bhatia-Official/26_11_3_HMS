package com.caresync.backend.security;

import com.caresync.backend.common.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> validation(MethodArgumentNotValidException exception) {
        return ResponseEntity.badRequest().body(new AuthDtos.ErrorResponse("Invalid request"));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unreadableRequest(HttpMessageNotReadableException exception) {
        return ResponseEntity.badRequest().body(new AuthDtos.ErrorResponse("Invalid request"));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unsupportedMethod(HttpRequestMethodNotSupportedException exception) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(new AuthDtos.ErrorResponse("Method not allowed"));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unsupportedMediaType(HttpMediaTypeNotSupportedException exception) {
        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE)
                .body(new AuthDtos.ErrorResponse("Unsupported media type"));
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> businessFailure(BusinessException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> dataConflict(DataIntegrityViolationException exception) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new AuthDtos.ErrorResponse("The requested change conflicts with existing data"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<AuthDtos.ErrorResponse> unexpected(Exception exception) {
        log.error("Unhandled API request failure ({})", exception.getClass().getName());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthDtos.ErrorResponse("Request could not be completed"));
    }
}
