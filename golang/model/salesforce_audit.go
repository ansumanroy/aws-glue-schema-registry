package model

// SalesforceAudit represents a Salesforce audit event
// Maps to the SalesforceAudit Avro/JSON schema
type SalesforceAudit struct {
	EventID      string `json:"eventId" avro:"eventId"`
	EventName    string `json:"eventName" avro:"eventName"`
	Timestamp    int64  `json:"timestamp" avro:"timestamp"`
	EventDetails string `json:"eventDetails" avro:"eventDetails"`
}

// ToMap converts SalesforceAudit to a map
func (s *SalesforceAudit) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"eventId":      s.EventID,
		"eventName":    s.EventName,
		"timestamp":    s.Timestamp,
		"eventDetails": s.EventDetails,
	}
}

// FromMap creates SalesforceAudit from a map
func (s *SalesforceAudit) FromMap(data map[string]interface{}) {
	if val, ok := data["eventId"].(string); ok {
		s.EventID = val
	}
	if val, ok := data["eventName"].(string); ok {
		s.EventName = val
	}
	if val, ok := data["timestamp"].(int64); ok {
		s.Timestamp = val
	}
	if val, ok := data["eventDetails"].(string); ok {
		s.EventDetails = val
	}
}

