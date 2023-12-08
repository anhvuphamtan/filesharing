resource "aws_s3_bucket_policy" "S3_bucket_policy" {
    bucket = var.S3_BUCKET_NAME
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "s3_cloudfront_website",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${var.S3_BUCKET_NAME}/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": [
                        "${var.CLOUDFRONT_DISTRIBUTION_UPLOAD_ARN}",
                        "${var.CLOUDFRONT_DISTRIBUTION_DOWNLOAD_ARN}"
                    ]
                }
            }
        }
    ]
}
EOF

}