variable "REGION" {
    type    = string
    default = "ap-southeast-1"
}

variable "S3_BUCKET_REGIONAL_DOMAIN_NAME" {
    type = string
}

variable "S3_BUCKET_ID" {
    type = string
}

variable "CLOUDFRONT_OAC_ID" {
    type = string
} 

variable "CACHE_POLICY" {
    type    = string
    default = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Caching Optimized
}

variable "LAMBDA_EDGE_ARN" {
    type = string
}

variable "CLOUDFRONT_TAGS" {
    type    = map(string)
    default = {
        Name = "STYL Cloudfront distribution Upload"
    }
}

variable "APIGW_NAME" {
    type = string
}

variable "APIGW_TAGS" {
    type    = map(string)
    default = {
        Name = "STYL Cloudfront API Gateway"
    }
}

variable "LAMBDA_FUNCTION_NAME" {
    type = string
}

variable "LAMBDA_RUNTIME" {
    type = string
}

variable "LAMBDA_ARCHITECTURE" {
    type    = string
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

variable "ROOT_WEBSITE" {
    type = string
}