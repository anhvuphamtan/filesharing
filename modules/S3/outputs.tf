output "_S3_BUCKET_REGIONAL_DOMAIN_NAME" {
    value = aws_s3_bucket.styl_file_upload_download_bucket.bucket_regional_domain_name
}

output "_S3_BUCKET_NAME" {
    value = aws_s3_bucket.styl_file_upload_download_bucket.bucket
}

output "_S3_BUCKET_ID" {
    value = aws_s3_bucket.styl_file_upload_download_bucket.id
}

output "_S3_BUCKET_ARN" {
    value = aws_s3_bucket.styl_file_upload_download_bucket.arn
}

output "_CLOUDFRONT_OAC_ID" {
    value = aws_cloudfront_origin_access_control.cloudfront_oac.id
}

