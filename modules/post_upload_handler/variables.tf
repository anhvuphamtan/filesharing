variable "REGION" {
    type = string
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
    default = "x86_64"
}

variable "LAMBDA_ROLE_NAME" {
    type = string
}

variable "LAMBDA_TAGS" {
    type = map(string)
}

variable "DYNAMODB_TABLE_NAME" {
    type = string
}

variable "S3_BUCKET_ID" {
    type = string
}

variable "S3_BUCKET_ARN" {
    type = string
}