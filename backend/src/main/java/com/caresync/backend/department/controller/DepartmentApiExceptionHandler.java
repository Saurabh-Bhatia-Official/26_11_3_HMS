package com.caresync.backend.department.controller;

import com.caresync.backend.department.service.DepartmentApiException;
import com.caresync.backend.security.AuthDtos;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = DepartmentController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class DepartmentApiExceptionHandler {
    @ExceptionHandler(DepartmentApiException.class)
    public ResponseEntity<AuthDtos.ErrorResponse> departmentError(DepartmentApiException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthDtos.ErrorResponse(exception.getMessage()));
    }
}
