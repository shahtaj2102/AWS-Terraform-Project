# AWS-Terraform-Project

[![AWS VPC Architecture](aws_vpc_diagram.png)](aws_vpc_diagram.png)

## 🎯 Project Overview

This Terraform project deploys a **production-ready AWS VPC** with public and private subnets across multiple Availability Zones, complete with Internet Gateway for public access and NAT Gateway for secure private outbound connectivity. Perfect for your first AWS infrastructure project!

**Key Features:**
- 3-tier VPC architecture (10.0.0.0/16)
- 3 Public subnets (direct internet access)
- 3 Private subnets (NAT Gateway outbound only)
- High availability across 3 AZs
- Auto-assigned public IPs on public subnets
- Secure routing with dedicated route tables

## 🏗️ Architecture Diagram

![AWS VPC Architecture](aws_vpc_diagram.png)

**What gets created:**
```
VPC: demo_vpc (10.0.0.0/16)
├── Public Subnets (3 AZs): 10.0.x.0/24 → Internet Gateway
├── Private Subnets (3 AZs): 10.0.y.0/24 → NAT Gateway  
├── Internet Gateway (IGW)
├── NAT Gateway + Elastic IP (public_subnet_1)
├── Public Route Table (0.0.0.0/0 → IGW)
└── Private Route Table (0.0.0.0/0 → NAT)
```

## 📁 Project Structure
```
First-AWS-Project/
├── main.tf              # Core infrastructure
├── variables.tf         # Configurable parameters
├── outputs.tf           # Queryable resource IDs
├── terraform.tfvars     # Environment overrides
├── aws_vpc_diagram.png  # Architecture visualization
└── README.md           # You're reading it!
```


## 🚀 Quick Start

1. **Prerequisites**
   # Install Terraform
   # AWS CLI configured with credentials
   aws configure



