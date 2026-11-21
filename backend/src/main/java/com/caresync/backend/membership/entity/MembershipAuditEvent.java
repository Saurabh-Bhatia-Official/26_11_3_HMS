package com.caresync.backend.membership.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "membership_audit_events", indexes = {
        @Index(name = "ix_membership_audit_membership_time", columnList = "membership_id, occurred_at")
})
public class MembershipAuditEvent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false)
    private HospitalMembership membership;

    @Column(name = "actor_account_id", nullable = false)
    private Long actorAccountId;

    @Column(name = "event_type", nullable = false, length = 24)
    private String eventType;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    protected MembershipAuditEvent() {}

    public MembershipAuditEvent(HospitalMembership membership, Long actorAccountId, String eventType, Instant occurredAt) {
        this.membership = membership;
        this.actorAccountId = actorAccountId;
        this.eventType = eventType;
        this.occurredAt = occurredAt;
    }

    public Long getId() { return id; }
    public Long getActorAccountId() { return actorAccountId; }
    public String getEventType() { return eventType; }
    public Instant getOccurredAt() { return occurredAt; }
}
