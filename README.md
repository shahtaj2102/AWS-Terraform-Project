# AWS Multi-AZ VPC Networking Foundation (Terraform)

[![AWS VPC Architecture](aws_vpc_diagram.png)](aws_vpc_diagram.png)

A Terraform configuration that provisions a production-style, multi-AZ VPC networking foundation on AWS — public and private subnets across three Availability Zones, Internet Gateway, NAT Gateway, and route tables, built with infrastructure as code.

This project focuses on the **networking layer**. It does not currently deploy any compute resources (EC2, load balancers, or auto scaling) — it's the foundation that a compute or application layer would sit on top of.

## What It Builds

- 1 VPC (`10.0.0.0/16`)
- 3 public subnets, one per Availability Zone
- 3 private subnets, one per Availability Zone
- 1 Internet Gateway (for public subnet internet access)
- 1 NAT Gateway with an Elastic IP (for private subnet outbound internet access)
- Route tables and associations wiring public subnets to the Internet Gateway and private subnets to the NAT Gateway

## Architecture

The diagram above illustrates the general pattern implemented — a VPC spanning three Availability Zones, each with a paired public and private subnet, a single NAT Gateway with an Elastic IP, and separate public/private route tables. (Note: the CIDR values shown in the diagram are illustrative placeholders — see the exact ranges used in this project in the table below.)

All three private subnets route outbound traffic through a single shared NAT Gateway located in the first public subnet.

## Subnet CIDR Breakdown

| Subnet | AZ | CIDR Block | Type |
|---|---|---|---|
| public_subnet_1 | AZ 1 | 10.0.101.0/24 | Public |
| public_subnet_2 | AZ 2 | 10.0.102.0/24 | Public |
| public_subnet_3 | AZ 3 | 10.0.103.0/24 | Public |
| private_subnet_1 | AZ 1 | 10.0.1.0/24 | Private |
| private_subnet_2 | AZ 2 | 10.0.2.0/24 | Private |
| private_subnet_3 | AZ 3 | 10.0.3.0/24 | Private |

Subnet CIDRs are calculated dynamically with Terraform's `cidrsubnet()` function rather than hardcoded, so the ranges scale automatically if the base VPC CIDR changes.

## Project Structure

```
.
├── main.tf        # VPC, subnets, route tables, IGW, NAT Gateway, EIP
├── variable.tf    # Input variable declarations
├── output.tf      # Output values
├── terraform.tf   # Terraform version and provider requirements
```

## Requirements

| Name | Version |
|---|---|
| Terraform | >= 1.0.0 |
| AWS Provider | >= 6.31.0 |
| AWS Account | Active, with credentials configured locally (e.g. via `aws configure`) |

## Usage

```bash
# Initialize Terraform and download the AWS provider
terraform init

# Preview the resources that will be created
terraform plan

# Provision the infrastructure
terraform apply

# Tear everything down when finished
terraform destroy
```

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | The ID of the created VPC |

## Possible Improvements

This project intentionally stays scoped to the networking layer. Some known limitations and natural next steps:

- **Single NAT Gateway**: all private subnets currently share one NAT Gateway for simplicity and cost. A production setup would typically use one NAT Gateway per AZ for high availability.
- **Unused `aws_region` variable**: the variable is declared but the provider block currently hardcodes `us-east-1` directly rather than referencing it.
- **No compute layer yet**: this repo does not include EC2 instances, an Application Load Balancer, or Auto Scaling — it's a foundation that a future compute/application layer could build on.
- **Limited outputs**: only `vpc_id` is currently exported; subnet IDs and the NAT Gateway ID would be useful additions for downstream modules.

## Author

Shahtaj Singh Gill
[LinkedIn](https://www.linkedin.com/in/shahtaj-aws-sap-toronto/) · [GitHub](https://github.com/shahtaj2102)
