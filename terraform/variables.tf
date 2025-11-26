variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "ca_certificate_path" {
  description = "Path to the local PEM file for the Trust Anchor"
  type        = string
  default     = "homelab-ca.pem"
}