resource "aws_s3_bucket" "styl_file_upload_download_bucket" {
    bucket = var.BUCKET_NAME

    tags = var.S3_BUCKET_TAGS
}

resource "aws_s3_object" "bucket_content_upload" {
    bucket                  = aws_s3_bucket.styl_file_upload_download_bucket.bucket 
    key                     = "upload.html"
    source                  = "./static_web/upload.html"
    server_side_encryption  = "AES256"
    content_type            = "text/html"

    tags                    = var.S3_BUCKET_TAGS
}

resource "aws_s3_object" "bucket_content_download" {
    bucket                 = aws_s3_bucket.styl_file_upload_download_bucket.bucket
    key                    = "download.html"
    source                 = "./static_web/download.html"
    server_side_encryption = "AES256"
    content_type           = "text/html"
    
    tags                   = var.S3_BUCKET_TAGS
}

resource "aws_s3_bucket_versioning" "styl_file_upload_download_bucket_versioning" {
    bucket = aws_s3_bucket.styl_file_upload_download_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_cloudfront_origin_access_control" "cloudfront_oac" {
    name                              = var.CLOUDFRONT_OAC_NAME
    description                       = "Cloudfront OAC to S3"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}