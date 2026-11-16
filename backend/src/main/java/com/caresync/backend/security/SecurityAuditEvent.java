package com.caresync.backend.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "security_audit_events", indexes = {
        @Index(name = "ix_security_audit_occurred_at", columnList = "occurred_at"),
        @Index(name = "ix_security_audit_account_id", columnList = "account_id")
})
public class SecurityAuditEvent {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "event_type", nullable = false, length = 32)
    private String eventType;
    @Column(name = "account_id")
    private Long accountId;
    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    protected SecurityAuditEvent() {}
    public SecurityAuditEvent(String eventType, Long accountId, Instant occurredAt) {
        this.eventType = eventType;
        this.accountId = accountId;
        this.occurredAt = occurredAt;
    }
    public Long getId() { return id; }
    public String getEventType() { return eventType; }
    public Long getAccountId() { return accountId; }
    public Instant getOccurredAt() { return occurredAt; }
}
