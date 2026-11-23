package com.caresync.backend.staff.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDate;

@Entity
@Table(name = "staff")
public class StaffMember extends HospitalScopedEntity {
    @Column(nullable = false, length = 160)
    private String name;

    @Column(nullable = false, length = 16)
    private String gender;

    @Column(name = "date_of_birth")
    private LocalDate dob;

    @Column(nullable = false, length = 32)
    private String phone;

    @Column(length = 254)
    private String email;

    @Column(nullable = false, length = 500)
    private String address = "";

    @Column(nullable = false, length = 32)
    private String role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;

    @Column(nullable = false, length = 160)
    private String qualification = "";

    @Column(name = "registration_number", length = 64)
    private String registrationNumber;

    @Column(name = "photo_path", length = 500)
    private String photoPath;

    @Column(name = "specialisation", nullable = false, length = 160)
    private String specialisation = "";

    @Column(name = "consultation_fee_paise", nullable = false)
    private long consultationFeePaise;

    @Column(name = "followup_fee_paise", nullable = false)
    private long followupFeePaise;

    @Column(name = "followup_days", nullable = false)
    private int followupDays = 7;

    @Column(name = "max_slots_per_day", nullable = false)
    private int maxSlotsPerDay = 30;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    protected StaffMember() {}

    public StaffMember(long hospitalId, String name, String gender, LocalDate dob, String phone, String email,
                       String address, String role, Department department, String qualification,
                       String registrationNumber, String photoPath, String specialisation,
                       long consultationFeePaise, long followupFeePaise, int followupDays,
                       int maxSlotsPerDay, boolean active) {
        super(hospitalId);
        update(name, gender, dob, phone, email, address, role, department, qualification, registrationNumber,
                photoPath, specialisation, consultationFeePaise, followupFeePaise, followupDays, maxSlotsPerDay, active);
    }

    public void update(String name, String gender, LocalDate dob, String phone, String email, String address,
                       String role, Department department, String qualification, String registrationNumber,
                       String photoPath, String specialisation, long consultationFeePaise, long followupFeePaise,
                       int followupDays, int maxSlotsPerDay, boolean active) {
        this.name = name;
        this.gender = gender;
        this.dob = dob;
        this.phone = phone;
        this.email = email;
        this.address = address == null ? "" : address;
        this.role = role;
        this.department = department;
        this.qualification = qualification == null ? "" : qualification;
        this.registrationNumber = registrationNumber;
        this.photoPath = photoPath;
        this.specialisation = specialisation == null ? "" : specialisation;
        this.consultationFeePaise = consultationFeePaise;
        this.followupFeePaise = followupFeePaise;
        this.followupDays = followupDays;
        this.maxSlotsPerDay = maxSlotsPerDay;
        this.active = active;
    }

    public String getName() { return name; }
    public String getGender() { return gender; }
    public LocalDate getDob() { return dob; }
    public String getPhone() { return phone; }
    public String getEmail() { return email; }
    public String getAddress() { return address; }
    public String getRole() { return role; }
    public Department getDepartment() { return department; }
    public String getQualification() { return qualification; }
    public String getRegistrationNumber() { return registrationNumber; }
    public String getPhotoPath() { return photoPath; }
    public String getSpecialisation() { return specialisation; }
    public long getConsultationFeePaise() { return consultationFeePaise; }
    public long getFollowupFeePaise() { return followupFeePaise; }
    public int getFollowupDays() { return followupDays; }
    public int getMaxSlotsPerDay() { return maxSlotsPerDay; }
    public boolean isActive() { return active; }
}
