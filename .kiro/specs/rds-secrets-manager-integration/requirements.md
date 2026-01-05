# Requirements Document

## Introduction

This document specifies the requirements for integrating AWS RDS PostgreSQL with AWS Secrets Manager for automatic credential management. The current Terraform configuration creates a separate secret but does not use RDS's native integration with Secrets Manager, which provides automatic password rotation and tighter integration.

## Glossary

- **RDS**: Amazon Relational Database Service - AWS managed database service
- **Secrets_Manager**: AWS Secrets Manager - service for storing and managing secrets
- **Master_User_Secret**: RDS-managed secret that stores database credentials
- **Terraform_Module**: Reusable Terraform configuration component
- **Password_Rotation**: Automatic periodic changing of database passwords

## Requirements

### Requirement 1: RDS Native Secrets Manager Integration

**User Story:** As a DevOps engineer, I want RDS to automatically manage database credentials in Secrets Manager, so that I have native AWS integration with automatic rotation capabilities.

#### Acceptance Criteria

1. WHEN the RDS instance is created, THE System SHALL enable `manage_master_user_password` to use RDS-managed secrets
2. WHEN RDS manages the password, THE System SHALL store credentials in a secret with a configurable KMS key
3. WHEN the RDS instance is created, THE System SHALL output the ARN of the RDS-managed secret
4. THE System SHALL NOT create a separate `random_password` resource when using RDS-managed secrets
5. THE System SHALL NOT create a separate `aws_secretsmanager_secret` resource when using RDS-managed secrets

### Requirement 2: Backward Compatibility and Migration

**User Story:** As a DevOps engineer, I want to migrate from manually-managed secrets to RDS-managed secrets, so that I can adopt the new approach without breaking existing infrastructure.

#### Acceptance Criteria

1. WHEN migrating to RDS-managed secrets, THE System SHALL provide clear documentation on the migration process
2. WHEN the old secret exists, THE System SHALL allow manual cleanup of the deprecated secret resources
3. THE System SHALL maintain the same secret name pattern for consistency
4. THE System SHALL preserve all database connection parameters (host, port, dbname, username)

### Requirement 3: Secret Access and Outputs

**User Story:** As a developer, I want to access database credentials from the RDS-managed secret, so that my applications can connect to the database securely.

#### Acceptance Criteria

1. WHEN the RDS instance is created, THE System SHALL output the secret ARN via Terraform outputs
2. WHEN querying the secret, THE System SHALL return credentials in JSON format with username, password, host, port, and dbname
3. THE System SHALL provide the secret ARN to dependent modules (like DMS) that need database credentials
4. THE System SHALL document how to retrieve credentials using AWS CLI and SDK

### Requirement 4: KMS Encryption Configuration

**User Story:** As a security engineer, I want database credentials encrypted with a specific KMS key, so that I can meet compliance requirements for encryption at rest.

#### Acceptance Criteria

1. WHERE a KMS key is specified, THE System SHALL use that key to encrypt the RDS-managed secret
2. WHERE no KMS key is specified, THE System SHALL use the default AWS-managed key
3. THE System SHALL accept a KMS key ARN or ID as a variable input
4. THE System SHALL validate that the KMS key exists and is accessible

### Requirement 5: Terraform State Management

**User Story:** As a DevOps engineer, I want to safely remove deprecated secret resources from Terraform state, so that I can complete the migration without destroying resources.

#### Acceptance Criteria

1. WHEN removing deprecated resources, THE System SHALL provide commands to remove them from state without deletion
2. THE System SHALL document the exact `terraform state rm` commands needed
3. THE System SHALL verify that no dependent resources reference the deprecated secrets
4. WHEN applying changes, THE System SHALL not attempt to destroy the old secret during migration
