package com.caresync.backend.pharmacy.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "pharmacy_suppliers")
public class Supplier extends HospitalScopedEntity {
    @Column(nullable = false, length = 160)
    private String name;

    @Column(name = "contact_person", nullable = false, length = 160)
    private String contactPerson = "";

    @Column(nullable = false, length = 32)
    private String phone = "";

    @Column(length = 254)
    private String email;

    @Column(nullable = false, length = 500)
    private String address = "";

    @Column(name = "gst_no", length = 32)
    private String gstNo;

    protected Supplier() {}

    public Supplier(long hospitalId, String name, String contactPerson, String phone, String email,
                    String address, String gstNo) {
        super(hospitalId);
        update(name, contactPerson, phone, email, address, gstNo);
    }

    public void update(String name, String contactPerson, String phone, String email, String address, String gstNo) {
        this.name = name;
        this.contactPerson = contactPerson == null ? "" : contactPerson;
        this.phone = phone == null ? "" : phone;
        this.email = email;
        this.address = address == null ? "" : address;
        this.gstNo = gstNo;
    }

    public String getName() { return name; }
    public String getContactPerson() { return contactPerson; }
    public String getPhone() { return phone; }
    public String getEmail() { return email; }
    public String getAddress() { return address; }
    public String getGstNo() { return gstNo; }
}
