package com.caresync.backend.common.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/** Zero-based page request. Missing values default to page 0 and size 20. */
public record PaginationRequest(
        @Min(0) Integer page,
        @Min(1) @Max(100) Integer size) {

    public static final int DEFAULT_PAGE = 0;
    public static final int DEFAULT_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;

    public PaginationRequest {
        page = page == null ? DEFAULT_PAGE : page;
        size = size == null ? DEFAULT_SIZE : size;
    }

    /** Offset is long-valued to avoid integer overflow for large page numbers. */
    public long offset() {
        return (long) page * size;
    }
}
