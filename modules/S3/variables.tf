variable "BUCKET_NAME" {
    type = string 
}

variable "S3_BUCKET_TAGS" {
    type = map(string) 
}

variable "CLOUDFRONT_OAC_NAME" {
    type = string
}