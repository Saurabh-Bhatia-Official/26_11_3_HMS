package com.caresync.backend.appointment.entity;

import com.caresync.backend.membership.entity.HospitalMembership;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "appointment_events", indexes = @Index(name = "ix_appointment_events_hospital_appointment_time",
        columnList = "hospital_uuid, appointment_uuid, occurred_at"))
public class AppointmentEvent {
    @Id
    @Column(name = "event_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_uuid", nullable = false, updatable = false)
    private Appointment appointment;

    @Column(name = "hospital_uuid", nullable = false, updatable = false)
    private UUID hospitalUuid;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "actor_membership_id", nullable = false, updatable = false)
    private HospitalMembership actorMembership;

    @Column(name = "event_type", nullable = false, length = 24, updatable = false)
    private String eventType;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status", length = 16, updatable = false)
    private AppointmentStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", length = 16, updatable = false)
    private AppointmentStatus newStatus;

    @Column(name = "previous_starts_at", updatable = false)
    private OffsetDateTime previousStartsAt;
    @Column(name = "previous_ends_at", updatable = false)
    private OffsetDateTime previousEndsAt;
    @Column(name = "new_starts_at", updatable = false)
    private OffsetDateTime newStartsAt;
    @Column(name = "new_ends_at", updatable = false)
    private OffsetDateTime newEndsAt;

    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt;

    protected AppointmentEvent() {}

    public AppointmentEvent(UUID id, Appointment appointment, UUID hospitalUuid, HospitalMembership actor,
                           String eventType, AppointmentStatus previousStatus, AppointmentStatus newStatus,
                           OffsetDateTime previousStart, OffsetDateTime previousEnd,
                           OffsetDateTime newStart, OffsetDateTime newEnd, Instant occurredAt) {
        this.id = id;
        this.appointment = appointment;
        this.hospitalUuid = hospitalUuid;
        this.actorMembership = actor;
        this.eventType = eventType;
        this.previousStatus = previousStatus;
        this.newStatus = newStatus;
        this.previousStartsAt = previousStart;
        this.previousEndsAt = previousEnd;
        this.newStartsAt = newStart;
        this.newEndsAt = newEnd;
        this.occurredAt = occurredAt;
    }

    public UUID getId() { return id; }
    public Appointment getAppointment() { return appointment; }
    public UUID getHospitalUuid() { return hospitalUuid; }
    public HospitalMembership getActorMembership() { return actorMembership; }
    public String getEventType() { return eventType; }
    public AppointmentStatus getPreviousStatus() { return previousStatus; }
    public AppointmentStatus getNewStatus() { return newStatus; }
    public OffsetDateTime getPreviousStartsAt() { return previousStartsAt; }
    public OffsetDateTime getPreviousEndsAt() { return previousEndsAt; }
    public OffsetDateTime getNewStartsAt() { return newStartsAt; }
    public OffsetDateTime getNewEndsAt() { return newEndsAt; }
    public Instant getOccurredAt() { return occurredAt; }
}
