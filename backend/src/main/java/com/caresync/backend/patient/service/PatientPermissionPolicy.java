package com.caresync.backend.patient.service;

import com.caresync.backend.membership.entity.MembershipRole;

/** Server-side Patient Registry policy approved for Sprint implementation. */
public final class PatientPermissionPolicy {
    private PatientPermissionPolicy() {}

    public static boolean canView(MembershipRole role) {
        return role == MembershipRole.HOSPITAL_SUPER_ADMIN || role == MembershipRole.ADMIN
                || role == MembershipRole.RECEPTIONIST || role == MembershipRole.DOCTOR
                || role == MembershipRole.NURSE;
    }

    public static boolean canCreate(MembershipRole role) {
        return role == MembershipRole.HOSPITAL_SUPER_ADMIN || role == MembershipRole.ADMIN
                || role == MembershipRole.RECEPTIONIST;
    }

    public static boolean canEditDemographics(MembershipRole role) {
        return canCreate(role);
    }

    public static boolean canManageStatusOrArchive(MembershipRole role) {
        return role == MembershipRole.HOSPITAL_SUPER_ADMIN || role == MembershipRole.ADMIN;
    }
}
