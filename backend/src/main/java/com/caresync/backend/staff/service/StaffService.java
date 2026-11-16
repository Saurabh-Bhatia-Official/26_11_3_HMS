package com.caresync.backend.staff.service;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.staff.dto.StaffDtos;
import com.caresync.backend.staff.entity.Department;
import com.caresync.backend.staff.entity.StaffMember;
import com.caresync.backend.staff.repository.DepartmentRepository;
import com.caresync.backend.staff.repository.StaffRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class StaffService {
    private final AccessContext access;
    private final DepartmentRepository departments;
    private final StaffRepository staff;

    public StaffService(AccessContext access, DepartmentRepository departments, StaffRepository staff) {
        this.access = access;
        this.departments = departments;
        this.staff = staff;
    }

    @Transactional(readOnly = true)
    public List<StaffDtos.DepartmentResponse> departments() {
        return departments.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(access.hospitalId())
                .stream().map(StaffService::departmentResponse).toList();
    }

    public StaffDtos.DepartmentResponse createDepartment(StaffDtos.DepartmentRequest request) {
        Department department = new Department(access.hospitalId(), request.name().trim(), request.description());
        if (Boolean.FALSE.equals(request.active())) department.update(request.name().trim(), request.description(), false);
        return departmentResponse(departments.save(department));
    }

    public StaffDtos.DepartmentResponse updateDepartment(long id, StaffDtos.DepartmentRequest request) {
        Department department = findDepartment(id);
        department.update(request.name().trim(), request.description(), !Boolean.FALSE.equals(request.active()));
        return departmentResponse(department);
    }

    public void deleteDepartment(long id) {
        Department department = findDepartment(id);
        department.markDeleted();
    }

    @Transactional(readOnly = true)
    public List<StaffDtos.StaffResponse> list(String role) {
        long hospitalId = access.hospitalId();
        List<StaffMember> members = role == null || role.isBlank()
                ? staff.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(hospitalId)
                : staff.findAllByHospitalIdAndRoleAndDeletedFalseOrderByNameAsc(hospitalId, role);
        return members.stream().map(StaffService::staffResponse).toList();
    }

    @Transactional(readOnly = true)
    public StaffDtos.StaffResponse get(long id) {
        return staffResponse(findStaff(id));
    }

    public StaffDtos.StaffResponse create(StaffDtos.StaffRequest request) {
        StaffMember member = new StaffMember(access.hospitalId(), request.name().trim(), request.gender(),
                request.dob(), request.phone().trim(), request.email(), request.address(), request.role(),
                departmentFor(request.departmentId()), request.qualification(), request.regNo(), request.photoPath(),
                request.specialisation(), request.consultationFeePaise(), request.followupFeePaise(),
                request.followupDays() == null ? 7 : request.followupDays(),
                request.maxSlotsPerDay() == null ? 30 : request.maxSlotsPerDay(),
                !Boolean.FALSE.equals(request.active()));
        return staffResponse(staff.save(member));
    }

    public StaffDtos.StaffResponse update(long id, StaffDtos.StaffRequest request) {
        StaffMember member = findStaff(id);
        member.update(request.name().trim(), request.gender(), request.dob(), request.phone().trim(),
                request.email(), request.address(), request.role(), departmentFor(request.departmentId()),
                request.qualification(), request.regNo(), request.photoPath(), request.specialisation(),
                request.consultationFeePaise(), request.followupFeePaise(),
                request.followupDays() == null ? 7 : request.followupDays(),
                request.maxSlotsPerDay() == null ? 30 : request.maxSlotsPerDay(),
                !Boolean.FALSE.equals(request.active()));
        return staffResponse(member);
    }

    public void delete(long id) {
        findStaff(id).markDeleted();
    }

    private Department departmentFor(Long id) {
        if (id == null) return null;
        return departments.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Department"));
    }

    private Department findDepartment(long id) {
        return departments.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Department"));
    }

    private StaffMember findStaff(long id) {
        return staff.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Staff member"));
    }

    private static StaffDtos.DepartmentResponse departmentResponse(Department department) {
        return new StaffDtos.DepartmentResponse(department.getId(), department.getUuid(), department.getName(),
                department.getDescription(), department.isActive(), department.getCreatedAt(), department.getUpdatedAt());
    }

    private static StaffDtos.StaffResponse staffResponse(StaffMember member) {
        Department department = member.getDepartment();
        return new StaffDtos.StaffResponse(member.getId(), member.getUuid(), member.getName(), member.getGender(),
                member.getDob(), member.getPhone(), member.getEmail(), member.getAddress(), member.getRole(),
                department == null ? null : department.getId(), department == null ? "" : department.getName(),
                member.getQualification(), member.getRegistrationNumber(), member.getPhotoPath(),
                member.getSpecialisation(), member.getConsultationFeePaise(), member.getFollowupFeePaise(),
                member.getFollowupDays(), member.getMaxSlotsPerDay(), member.isActive(), member.getCreatedAt(),
                member.getUpdatedAt());
    }
}
