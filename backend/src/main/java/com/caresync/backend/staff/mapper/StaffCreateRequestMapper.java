package com.caresync.backend.staff.mapper;

import com.caresync.backend.staff.dto.StaffCreateRequest;
import com.caresync.backend.staff.service.StaffCreateCommand;

/** Pure mapping from the HTTP request contract to the application command. */
public final class StaffCreateRequestMapper {
    private static final String DEFAULT_STATUS = "Active";
    private static final int DEFAULT_CONSULTATION_FEE_PAISE = 0;

    private StaffCreateRequestMapper() {}

    public static StaffCreateCommand toCommand(StaffCreateRequest request) {
        if (request == null) throw new IllegalArgumentException("request must not be null");
        return new StaffCreateCommand(
                request.uuid(),
                request.name(),
                request.role(),
                request.regNo(),
                request.department(),
                request.phone(),
                request.email(),
                request.consultationFeePaise() == null
                        ? DEFAULT_CONSULTATION_FEE_PAISE : request.consultationFeePaise(),
                request.status() == null ? DEFAULT_STATUS : request.status(),
                request.qualification());
    }
}
