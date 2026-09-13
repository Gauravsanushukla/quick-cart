# QuickCart — Scalable Multi-Tier Cloud Infrastructure

An enterprise-grade, highly available, and fault-tolerant e-commerce infrastructure deployed on AWS using Terraform and automated via GitHub Actions CI/CD.

## 🏗️ Architecture Overview

- **Virtual Private Cloud (VPC):** Custom CIDR block with multi-AZ public subnets (`ap-south-1a`, `ap-south-1b`).
- **High Availability & Traffic Distribution:** AWS Application Load Balancer (ALB) dynamically routing traffic across healthy targets using Round-Robin.
- **Auto Scaling & Self-Healing:** Auto Scaling Group (ASG) maintaining a 2–4 instance capacity with Target Tracking (CPU 50%) policies.
- **State Management:** S3 Remote Backend with distributed state locking (`use_lockfile` / DynamoDB).
- **CI/CD Automation:** GitOps workflow using GitHub Actions for automated linting, validation, planning, and deployment.

## 🚀 Tech Stack

- **Cloud:** AWS (VPC, EC2, ALB, ASG, S3, IAM)
- **IaC:** Terraform v1.10+
- **CI/CD:** GitHub Actions
- **Web Tier:** Nginx / Apache on Amazon Linux 2023

## ⚙️ Quick Start

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan and Apply
terraform plan
terraform apply --auto-approve


---

### Task 3: Resume Bullets (Ready to Copy-Paste)

* **Scalable AWS Infrastructure:** Architected and deployed a multi-AZ, fault-tolerant e-commerce infrastructure leveraging AWS ALB, Auto Scaling Groups (ASG), and VPC across multiple Availability Zones in `ap-south-1`.
* **Infrastructure as Code (IaC):** Automated 100% of AWS cloud resource provisioning using modular Terraform with remote state locking and automated lifecycle management.
* **Continuous Integration & Delivery:** Designed an end-to-end GitOps pipeline using GitHub Actions to automate Terraform validation, execution plans, and zero-downtime deployments upon branch merges.
* **High Availability & Fault Tolerance:** Implemented dynamic target group health checks and self-healing Auto Scaling policies, ensuring 99.9% uptime during instance termination and traffic spikes.

---

Isko push kar do:
```powershell
git add README.md
git commit -m "docs: add comprehensive architecture readme and documentation"
git push origin main