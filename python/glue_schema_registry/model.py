"""Model classes for Glue Schema Registry."""

from dataclasses import dataclass
from typing import Optional


@dataclass
class SalesforceAudit:
    """Model class representing a Salesforce audit event.
    Maps to the SalesforceAudit Avro/JSON schema.
    """
    event_id: str
    event_name: str
    timestamp: int
    event_details: str
    
    def __post_init__(self):
        """Validate the object after initialization."""
        if not isinstance(self.timestamp, int):
            raise ValueError("timestamp must be an integer")
        if self.timestamp < 0:
            raise ValueError("timestamp must be non-negative")
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            'eventId': self.event_id,
            'eventName': self.event_name,
            'timestamp': self.timestamp,
            'eventDetails': self.event_details
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'SalesforceAudit':
        """Create from dictionary."""
        return cls(
            event_id=data.get('eventId', ''),
            event_name=data.get('eventName', ''),
            timestamp=data.get('timestamp', 0),
            event_details=data.get('eventDetails', '')
        )

