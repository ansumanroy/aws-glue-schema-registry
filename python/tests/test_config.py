"""Test configuration utility for loading test settings from config file.
Supports environment variable overrides.
"""

import os
import configparser
from pathlib import Path


class TestConfig:
    """Test configuration loader with environment variable support."""
    
    _config = None
    _config_file = Path(__file__).parent / "test-config.ini"
    
    @classmethod
    def _load_config(cls):
        """Load configuration from file."""
        if cls._config is not None:
            return cls._config
        
        cls._config = configparser.ConfigParser()
        if cls._config_file.exists():
            cls._config.read(cls._config_file)
        return cls._config
    
    @classmethod
    def get_registry_name(cls):
        """Get registry name with environment variable override."""
        env_value = os.getenv("GLUE_REGISTRY_NAME")
        if env_value:
            return env_value
        
        config = cls._load_config()
        return config.get("test", "glue.registry.name", fallback="glue-schema-registry-ansumanroy-6219")
    
    @classmethod
    def get_aws_region(cls):
        """Get AWS region with environment variable override."""
        env_value = os.getenv("AWS_REGION")
        if env_value:
            return env_value
        
        config = cls._load_config()
        return config.get("test", "aws.region", fallback="us-east-1")
    
    @classmethod
    def get_avro_schema_name(cls):
        """Get Avro schema name with environment variable override."""
        env_value = os.getenv("SCHEMA_NAME_AVRO")
        if env_value:
            return env_value
        
        config = cls._load_config()
        return config.get("test", "schema.name.avro", fallback="SalesforceAudit")
    
    @classmethod
    def get_json_schema_name(cls):
        """Get JSON schema name with environment variable override."""
        env_value = os.getenv("SCHEMA_NAME_JSON")
        if env_value:
            return env_value
        
        config = cls._load_config()
        return config.get("test", "schema.name.json", fallback="SalesAuditJSON")

