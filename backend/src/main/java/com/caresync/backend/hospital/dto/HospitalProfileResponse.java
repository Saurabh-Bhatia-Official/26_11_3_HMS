package com.caresync.backend.hospital.dto;

public record HospitalProfileResponse(String hospitalId, String name, String code, String type,
                                      String address, String phone, String email, String timeZone) {}
