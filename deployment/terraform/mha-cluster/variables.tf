variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
  default = "mha-tf-state"
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default = "mha-tf-state"
}
