package com.caresync.backend.patient.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record PatientUpdateRequest(
        @PositiveOrZero long version,
        @NotBlank @Size(max = 200) String name,
        @Pattern(regexp = "^(Male|Female|Other)$") String gender,
        @PastOrPresent LocalDate dateOfBirth,
        @Min(0) @Max(150) Integer ageYears,
        @Pattern(regexp = "^\\+?[0-9][0-9 ()-]{5,19}$") String phone,
        @Pattern(regexp = "^\\+?[0-9][0-9 ()-]{5,19}$") String alternatePhone,
        @Email @Size(max = 254) String email,
        @Size(max = 255) String address,
        @Size(max = 100) String city,
        @Size(max = 100) String state,
        @Size(max = 32) String pincode,
        @Pattern(regexp = "^(A\\+|A-|B\\+|B-|O\\+|O-|AB\\+|AB-)$") String bloodGroup,
        @Size(max = 160) String emergencyContactName,
        @Pattern(regexp = "^\\+?[0-9][0-9 ()-]{5,19}$") String emergencyContactPhone) {

    public PatientUpdateRequest {
        name = name == null ? null : name.trim();
        gender = blankToNull(gender);
        phone = blankToNull(phone);
        alternatePhone = blankToNull(alternatePhone);
        email = blankToNull(email);
        address = blankToNull(address);
        city = blankToNull(city);
        state = blankToNull(state);
        pincode = blankToNull(pincode);
        bloodGroup = blankToNull(bloodGroup);
        emergencyContactName = blankToNull(emergencyContactName);
        emergencyContactPhone = blankToNull(emergencyContactPhone);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
