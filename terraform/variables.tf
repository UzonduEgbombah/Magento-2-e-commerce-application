# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "service_name" {
  description = "Name of the Lightsail service"
  type        = string
}

variable "container_power" {
  description = "Lightsail container power"
  default     = "nano"
}

variable "container_scale" {
  description = "Number of containers to scale"
  default     = 1
}

variable "db_bundle_id" {
  description = "Database bundle ID"
  type        = string
}

variable "database_name" {
  description = "Master database name"
  type        = string
}

variable "database_user" {
  description = "Master database username"
  type        = string
}

variable "database_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for public access"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key for GenAI integration"
  type        = string
  sensitive   = true
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  default     = 60
}
