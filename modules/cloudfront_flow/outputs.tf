output "_CLOUDFRONT_DISTRIBUTION_ARN" {
    value = aws_cloudfront_distribution.cloudfront_distribution.arn
}

output "_CLOUDFRONT_DOMAIN" {
    value = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}