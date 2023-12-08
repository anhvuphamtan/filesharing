variable "REGION" {
    type    = string
    default = "ap-southeast-1"
}

variable "LAMBDA_FUNCTION_NAME" {
    type = string
}

variable "LAMBDA_RUNTIME" {
    type = string
}

variable "LAMBDA_ARCHITECTURE" {
    type = string
}

variable "LAMBDA_ROLE_NAME" {
    type = string
}

variable "S3_BUCKET_NAME" {
    type = string
}

variable "DYNAMODB_TABLE_NAME" {
    type = string
}