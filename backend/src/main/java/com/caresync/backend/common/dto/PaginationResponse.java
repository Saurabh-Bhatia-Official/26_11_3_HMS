package com.caresync.backend.common.dto;

import java.util.List;
import java.util.Objects;

/** Immutable page metadata and items for new paginated API responses. */
public record PaginationResponse<T>(
        List<T> items,
        int page,
        int size,
        long totalElements,
        long totalPages) {

    public PaginationResponse {
        items = List.copyOf(Objects.requireNonNull(items, "items"));
        if (page < 0) throw new IllegalArgumentException("page must be non-negative");
        if (size < 1 || size > PaginationRequest.MAX_PAGE_SIZE) {
            throw new IllegalArgumentException("size is outside the supported range");
        }
        if (totalElements < 0) throw new IllegalArgumentException("totalElements must be non-negative");
        long expectedPages = totalElements / size + (totalElements % size == 0 ? 0 : 1);
        if (totalPages != expectedPages) {
            throw new IllegalArgumentException("totalPages does not match totalElements and size");
        }
    }

    public static <T> PaginationResponse<T> of(
            List<T> items, PaginationRequest request, long totalElements) {
        Objects.requireNonNull(request, "request");
        if (request.page() < 0) throw new IllegalArgumentException("page must be non-negative");
        if (request.size() < 1 || request.size() > PaginationRequest.MAX_PAGE_SIZE) {
            throw new IllegalArgumentException("size is outside the supported range");
        }
        if (totalElements < 0) throw new IllegalArgumentException("totalElements must be non-negative");
        long totalPages = totalElements / request.size()
                + (totalElements % request.size() == 0 ? 0 : 1);
        return new PaginationResponse<>(items, request.page(), request.size(), totalElements, totalPages);
    }
}
