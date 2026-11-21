package com.caresync.backend.opd.entity;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum OpdVisitStatus {

    @JsonProperty("Waiting for Vitals")
    WAITING_FOR_VITALS,

    @JsonProperty("In Consultation")
    IN_CONSULTATION,

    @JsonProperty("Completed")
    COMPLETED
}
