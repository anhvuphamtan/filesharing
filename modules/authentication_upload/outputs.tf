output "_LAMBDA_EDGE_ARN" {
    value = aws_lambda_function.lambda_edge.qualified_arn
}

output "_COGNITO_USER_POOL_ID" {
  value = aws_cognito_user_pool.cognito_user_pool.id
}

output "_COGNITO_USER_POOL_DOMAIN" {
    value = aws_cognito_user_pool.cognito_user_pool.domain
}

output "_COGNITO_USER_POOL_CLIENT_ID" {
    value = aws_cognito_user_pool_client.cognito_user_pool_client.id
}

output "_COGNITO_USER_POOL_CLIENT_SECRET" {
    value = nonsensitive(aws_cognito_user_pool_client.cognito_user_pool_client.client_secret)
}


