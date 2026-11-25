package com.caresync.backend.staff.mapper;

import com.caresync.backend.staff.dto.StaffCreateRequest;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class StaffCreateRequestMapperTests {
    @Test
    void appliesOnlyDefaultsDefinedByTheActiveLocalStaffTable() {
        var request = new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", "Asha Rao", "Nurse", null, null,
                null, null, null, null, null);

        var command = StaffCreateRequestMapper.toCommand(request);

        assertEquals(0, command.consultationFeePaise());
        assertEquals("Active", command.status());
    }

    @Test
    void preservesExplicitValues() {
        var request = new StaffCreateRequest(
                "9a8f3d22-49ef-46b4-9ac4-156e84bd5172", "Asha Rao", "Nurse", "EMP-1", "ICU",
                "+91 9876543210", "asha@example.org", 12345, "On leave", "BSc Nursing");

        var command = StaffCreateRequestMapper.toCommand(request);

        assertEquals(request.uuid(), command.uuid());
        assertEquals(request.name(), command.name());
        assertEquals(request.role(), command.role());
        assertEquals(request.regNo(), command.regNo());
        assertEquals(request.department(), command.department());
        assertEquals(request.phone(), command.phone());
        assertEquals(request.email(), command.email());
        assertEquals(12345, command.consultationFeePaise());
        assertEquals("On leave", command.status());
        assertEquals(request.qualification(), command.qualification());
    }
}
