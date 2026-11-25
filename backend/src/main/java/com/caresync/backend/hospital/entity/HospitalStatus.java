package com.caresync.backend.hospital.entity;

/** Lifecycle states explicitly required for public hospital registration. */
public enum HospitalStatus {
    PENDING,
    APPROVED,
    REJECTED,
    SUSPENDED
}
