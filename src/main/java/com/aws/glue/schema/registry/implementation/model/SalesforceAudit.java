package com.aws.glue.schema.registry.implementation.model;

import java.util.Objects;

/**
 * Model class representing a Salesforce audit event.
 * Maps to the SalesforceAudit Avro schema.
 */
public class SalesforceAudit {
    private String eventId;
    private String eventName;
    private long timestamp;
    private String eventDetails;

    public SalesforceAudit() {
    }

    public SalesforceAudit(String eventId, String eventName, long timestamp, String eventDetails) {
        this.eventId = eventId;
        this.eventName = eventName;
        this.timestamp = timestamp;
        this.eventDetails = eventDetails;
    }

    public String getEventId() {
        return eventId;
    }

    public void setEventId(String eventId) {
        this.eventId = eventId;
    }

    public String getEventName() {
        return eventName;
    }

    public void setEventName(String eventName) {
        this.eventName = eventName;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    public String getEventDetails() {
        return eventDetails;
    }

    public void setEventDetails(String eventDetails) {
        this.eventDetails = eventDetails;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        SalesforceAudit that = (SalesforceAudit) o;
        return timestamp == that.timestamp &&
                Objects.equals(eventId, that.eventId) &&
                Objects.equals(eventName, that.eventName) &&
                Objects.equals(eventDetails, that.eventDetails);
    }

    @Override
    public int hashCode() {
        return Objects.hash(eventId, eventName, timestamp, eventDetails);
    }

    @Override
    public String toString() {
        return "SalesforceAudit{" +
                "eventId='" + eventId + '\'' +
                ", eventName='" + eventName + '\'' +
                ", timestamp=" + timestamp +
                ", eventDetails='" + eventDetails + '\'' +
                '}';
    }
}
