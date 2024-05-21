Here is a detailed README for a Terraform configuration using VPC, S3, and Lambda AWS services:

# Terraform AWS Infrastructure

## Overview

This Terraform configuration sets up a VPC, S3 bucket, and Lambda function. Best practices around security, cost optimization, and the AWS Well-Architected Framework have been followed.

## VPC

A VPC is configured with public and private subnets across two availability zones. Public subnets contain internet-facing resources and private subnets contain backend services not requiring internet access.

### Security

- VPC flow logs enabled to log network traffic
- Security groups restrict inbound and outbound traffic
- Private subnets and NAT gateway prevent direct internet access to backend services

### Cost Optimization

- VPC set to delete on termination to avoid unused resources persisting
- Purchase Reserved Instances for predictable workloads
- Right size VPC resources like subnets to meet capacity needs  

## S3 Bucket

An encrypted S3 bucket is created for secure storage.

### Security

- Enable bucket encryption with KMS
- Block public access and use IAM policies to control access
- Enable bucket versioning to easily restore from unintended overwrites

### Cost Optimization

- Set lifecycle rules to transition to Infrequent Access after 30 days and Glacier after 60 days
- Delete old versions after 365 days  
- Monitor usage and storage metrics to right size

## Lambda Function 

A Lambda function is used to process files from the S3 bucket.

### Security

- Function runs with minimum privilege IAM role
- VPC connectivity limits exposure of backend services  
- Environment variables used instead of hardcoded secrets

### Cost Optimization

- Allocate adequate memory to avoid out of memory errors which may retry
- Use Provisioned Concurrency to improve startup time for predictable workloads

## Well-Architected Framework

### Operational Excellence

- Infrastructure codified as IaC with Terraform for consistency and automation
- Monitoring and alerts configured for critical resources
- Change management process for reviewing and testing infrastructure changes

### Security

- Encryption enabled for data at rest and in transit
- Least privilege access with IAM roles 
- VPC design provides network isolation using private subnets

### Reliability

- Resources deployed across two availability zones for redundancy
- Backup critical data in S3 bucket with versioning
- Lambda retries configured for failed invocations

### Cost Optimization 

- Reserved Instances for steady state workloads
- Set resource lifecycles to expire unneeded resources
- Continually monitor and scale resources to meet usage demand

## Cost Breakdown

| Resource           | Usage             | Hourly Rate | Daily Cost | Monthly Cost |
|--------------------|-------------------|-------------|------------|--------------|
| t3.small (VPC)     | 24 hours          | $0.0208     | $0.50      | $15          |
| S3 Storage         | 50GB              | $0.023      | $1.15      | $35          |  
| Lambda             | 1M requests       | $0.20       | $4.80      | $144         |
| Data Transfer Out  | 50GB              | $0.09       | $4.50      | $135         |
| **Total**          |                   |             | **$10.95** | **$329**     |

Estimated total monthly cost is $329 based on services and usage outlined above. Data transfer and storage costs may vary monthly depending on actual usage.

Let me know if you would like me to clarify or expand on any part of this Terraform AWS infrastructure README!