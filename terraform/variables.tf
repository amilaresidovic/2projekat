variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ebs_size" {
  description = "Size of EBS volume in GB"
  default     = 10
}

variable "repo_url" {
  description = "Git repository URL"
  default     = "https://github.com/amilaresidovic/2projekat.git"
}