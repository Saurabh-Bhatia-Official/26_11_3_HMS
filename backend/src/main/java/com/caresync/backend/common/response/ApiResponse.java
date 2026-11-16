package com.caresync.backend.common.response;

/**
 * Immutable success envelope for new common/business API responses.
 * Existing authentication endpoints retain their established response DTOs.
 */
public record ApiResponse<T>(T data) {
    public static <T> ApiResponse<T> of(T data) {
        return new ApiResponse<>(data);
    }
}
