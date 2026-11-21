package com.caresync.backend.common.dto;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class PaginationResponseTests {
    @Test
    void createsImmutablePageAndCorrectPageCount() {
        List<String> source = new ArrayList<>(List.of("one", "two"));
        PaginationResponse<String> response = PaginationResponse.of(source, new PaginationRequest(1, 2), 5);

        source.add("three");
        assertEquals(List.of("one", "two"), response.items());
        assertEquals(1, response.page());
        assertEquals(2, response.size());
        assertEquals(5, response.totalElements());
        assertEquals(3, response.totalPages());
        assertThrows(UnsupportedOperationException.class, () -> response.items().add("four"));
    }

    @Test
    void emptyResultHasZeroPages() {
        PaginationResponse<String> response = PaginationResponse.of(
                List.of(), new PaginationRequest(null, null), 0);

        assertEquals(0, response.totalPages());
        assertEquals(List.of(), response.items());
    }

    @Test
    void rejectsNegativeTotals() {
        assertThrows(IllegalArgumentException.class, () -> PaginationResponse.of(
                List.of(), new PaginationRequest(0, 20), -1));
    }
}
