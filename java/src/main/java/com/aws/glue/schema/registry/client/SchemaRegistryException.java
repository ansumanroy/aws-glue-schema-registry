package com.aws.glue.schema.registry.client;

/**
 * Custom exception for Glue Schema Registry operations.
 * Provides error codes and MuleSoft-compatible error handling.
 */
public class SchemaRegistryException extends RuntimeException {
    
    private final ErrorCode errorCode;
    
    /**
     * Error codes for different types of schema registry errors.
     */
    public enum ErrorCode {
        SCHEMA_NOT_FOUND("SCHEMA_NOT_FOUND", "Schema not found in registry"),
        SCHEMA_VERSION_NOT_FOUND("SCHEMA_VERSION_NOT_FOUND", "Schema version not found"),
        SERIALIZATION_FAILED("SERIALIZATION_FAILED", "Failed to serialize data"),
        DESERIALIZATION_FAILED("DESERIALIZATION_FAILED", "Failed to deserialize data"),
        INVALID_SCHEMA("INVALID_SCHEMA", "Invalid schema definition"),
        REGISTRY_ACCESS_ERROR("REGISTRY_ACCESS_ERROR", "Failed to access schema registry"),
        CONFIGURATION_ERROR("CONFIGURATION_ERROR", "Configuration error"),
        UNKNOWN_ERROR("UNKNOWN_ERROR", "Unknown error occurred");
        
        private final String code;
        private final String description;
        
        ErrorCode(String code, String description) {
            this.code = code;
            this.description = description;
        }
        
        public String getCode() {
            return code;
        }
        
        public String getDescription() {
            return description;
        }
    }
    
    /**
     * Creates a new SchemaRegistryException with a message.
     * 
     * @param message Error message
     */
    public SchemaRegistryException(String message) {
        super(message);
        this.errorCode = ErrorCode.UNKNOWN_ERROR;
    }
    
    /**
     * Creates a new SchemaRegistryException with a message and cause.
     * 
     * @param message Error message
     * @param cause Throwable cause
     */
    public SchemaRegistryException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = ErrorCode.UNKNOWN_ERROR;
    }
    
    /**
     * Creates a new SchemaRegistryException with an error code and message.
     * 
     * @param errorCode Error code
     * @param message Error message
     */
    public SchemaRegistryException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
    
    /**
     * Creates a new SchemaRegistryException with an error code, message, and cause.
     * 
     * @param errorCode Error code
     * @param message Error message
     * @param cause Throwable cause
     */
    public SchemaRegistryException(ErrorCode errorCode, String message, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    /**
     * Gets the error code.
     * 
     * @return Error code
     */
    public ErrorCode getErrorCode() {
        return errorCode;
    }
    
    /**
     * Gets a detailed error message including error code.
     * 
     * @return Detailed error message
     */
    @Override
    public String getMessage() {
        return String.format("[%s] %s: %s", 
            errorCode.getCode(), 
            errorCode.getDescription(), 
            super.getMessage());
    }
    
    /**
     * Converts this exception to a MuleSoft-compatible exception if MuleSoft is available.
     * Returns this exception if MuleSoft is not available.
     * 
     * @return MuleSoft exception or this exception
     */
    public RuntimeException toMuleSoftException() {
        if (isMuleSoftAvailable()) {
            try {
                Class<?> muleRuntimeExceptionClass = Class.forName("org.mule.runtime.api.exception.MuleRuntimeException");
                
                // Create MuleSoft exception with error type
                Object muleException = muleRuntimeExceptionClass
                    .getConstructor(String.class, Throwable.class)
                    .newInstance(getMessage(), this);
                
                return (RuntimeException) muleException;
            } catch (Exception e) {
                // If reflection fails, return this exception
                return this;
            }
        }
        return this;
    }
    
    /**
     * Checks if MuleSoft classes are available.
     * 
     * @return true if MuleSoft is available
     */
    private boolean isMuleSoftAvailable() {
        try {
            Class.forName("org.mule.runtime.api.MuleContext");
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }
}
