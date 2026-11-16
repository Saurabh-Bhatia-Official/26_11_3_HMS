package com.caresync.backend.hospital.dto;

import java.util.UUID;

public record HospitalApprovalResponse(UUID hospitalUuid, String hospitalId, String name, String status) {}
