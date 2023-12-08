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

variable "COGNITO_USER_POOL_NAME" {
    type = string
}

variable "COGNITO_USER_POOL_DOMAIN" {
    type = string
}

variable "COGNITO_USER_POOL_CLIENT_NAME" {
    type = string
}

variable "DOMAIN_NAME" {
    type = string
}

variable "GOOGLE_CLIENT_ID" {
    type = string
}

variable "GOOGLE_CLIENT_SECRET" {
    type = string
}

variable "S3_BUCKET_NAME" {
    type = string
}

variable "COGNITO_TAGS" {
    type = map(string)
}