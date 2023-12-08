output "cognito_user_pool_id" {
  value = module.authentication_upload._COGNITO_USER_POOL_ID
}

# output.cognito_user_pool_client_id
output "cognito_user_pool_client_id" {
    value = module.authentication_upload._COGNITO_USER_POOL_CLIENT_ID
}

# output.cognito_user_pool_client_secret
output "cognito_user_pool_client_secret" {
    value = module.authentication_upload._COGNITO_USER_POOL_CLIENT_SECRET
}

# output.cognito_user_pool_doamin_url
output "cognito_user_pool_domain_url" {
    value = "${module.authentication_upload._COGNITO_USER_POOL_DOMAIN}.auth.ap-southeast-1.amazoncognito.com"
}

/*Output cloudfront domain*/
output "cloudfront_upload_domain_name" {
    value = module.cloudfront_flow_upload._CLOUDFRONT_DOMAIN
}

output "cloudfront_download_domain_name" {
    value = module.cloudfront_flow_download._CLOUDFRONT_DOMAIN
}
