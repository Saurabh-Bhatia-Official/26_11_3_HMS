package com.caresync.backend.staff.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "departments", uniqueConstraints = @UniqueConstraint(
        name = "uk_department_hospital_name", columnNames = {"hospital_id", "name"}))
public class Department extends HospitalScopedEntity {
    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 500)
    private String description = "";

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    protected Department() {}

    public Department(long hospitalId, String name, String description) {
        super(hospitalId);
        this.name = name;
        this.description = description == null ? "" : description;
    }

    public String getName() { return name; }
    public String getDescription() { return description; }
    public boolean isActive() { return active; }
    public void update(String name, String description, boolean active) {
        this.name = name;
        this.description = description == null ? "" : description;
        this.active = active;
    }
}
