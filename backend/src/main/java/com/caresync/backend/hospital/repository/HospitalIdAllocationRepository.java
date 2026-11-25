package com.caresync.backend.hospital.repository;

import com.caresync.backend.hospital.entity.HospitalIdAllocation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HospitalIdAllocationRepository extends JpaRepository<HospitalIdAllocation, Long> {}
