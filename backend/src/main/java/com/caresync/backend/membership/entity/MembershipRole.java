package com.caresync.backend.membership.entity;

import java.util.EnumSet;
import java.util.Set;

/** Hospital authorization roles; job titles and designations belong to Staff profiles. */
public enum MembershipRole {
    HOSPITAL_SUPER_ADMIN,
    ADMIN,
    DOCTOR,
    NURSE,
    RECEPTIONIST,
    PHARMACIST,
    LAB_TECHNICIAN,
    ACCOUNTS,
    STAFF;

    private static final Set<MembershipRole> GRANTABLE_BY_HOSPITAL_ADMIN =
            EnumSet.of(DOCTOR, NURSE, RECEPTIONIST, PHARMACIST, LAB_TECHNICIAN, ACCOUNTS, STAFF);

    public static boolean isGrantableByHospitalAdmin(MembershipRole role) {
        return GRANTABLE_BY_HOSPITAL_ADMIN.contains(role);
    }
}
