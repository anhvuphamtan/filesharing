# ---------------------------------------------- Region ---------------------------------------------- #
provider "aws" {
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# --------------------------------------------------------------------------------------------------- #





# ---------------------------------------------- Data ---------------------------------------------- #
data "aws_caller_identity" "aws_account" {}

data "archive_file" "lambda_zip_file" {
    type        = "zip"
    source_file     = "${path.module}/../../data/src/${var.LAMBDA_FUNCTION_NAME}.py"
    output_path     = "${path.module}/../../data/zip/${var.LAMBDA_FUNCTION_NAME}.zip"
}

# --------------------------------------------------------------------------------------------------- #





# ---------------------------------------------- Lamda ---------------------------------------------- #
resource "aws_lambda_function" "lambda_edge" {
    provider        = aws.us_east_1
    function_name   = var.LAMBDA_FUNCTION_NAME
    filename        = data.archive_file.lambda_zip_file.output_path
    handler         = "${var.LAMBDA_FUNCTION_NAME}.lambda_handler"
    runtime         = var.LAMBDA_RUNTIME
    architectures   = [
        var.LAMBDA_ARCHITECTURE
    ]

    role            = aws_iam_role.iam_role_lambda_edge_upload.arn
    timeout         = 5 
    publish         = true
    
}

resource "aws_iam_role" "iam_role_lambda_edge_upload" {
    name = var.LAMBDA_ROLE_NAME
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "edgelambda.amazonaws.com",
                    "lambda.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_lambda_edge_upload" {
    name = "policy_${var.LAMBDA_ROLE_NAME}"
    role = aws_iam_role.iam_role_lambda_edge_upload.id
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda_edge.function_name}:*"
        },

        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${var.S3_BUCKET_NAME}/*"
        },

        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:AdminDisableUser"
            ],
            "Resource": "arn:aws:cognito-idp:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:userpool/*"
        }
    
    ]
}
EOF
}

# --------------------------------------------------------------------------------------------------------- #





# ---------------------------------------------- Cognito ---------------------------------------------- #
resource "aws_cognito_user_pool" "cognito_user_pool" {
    name                        = var.COGNITO_USER_POOL_NAME
    auto_verified_attributes    = ["email"]
    mfa_configuration           = "OFF"

    account_recovery_setting {
        recovery_mechanism {
            name        = "admin_only"
            priority    = 1
        }
    }

  tags = var.COGNITO_TAGS
}


resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
    domain          = var.COGNITO_USER_POOL_DOMAIN
    user_pool_id    = aws_cognito_user_pool.cognito_user_pool.id
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
    name                                    = var.COGNITO_USER_POOL_CLIENT_NAME
    user_pool_id                            = aws_cognito_user_pool.cognito_user_pool.id
    
    allowed_oauth_flows                     = ["code"]
    allowed_oauth_flows_user_pool_client    = true
    allowed_oauth_scopes                    = ["email", "openid", "aws.cognito.signin.user.admin", "profile"]
    supported_identity_providers            = ["Google"]

    refresh_token_validity                  = 30   # 30 days
    access_token_validity                   = 60   # 60 minutes
    explicit_auth_flows                     = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
    callback_urls                           = ["https://${var.DOMAIN_NAME}/auth"]

    generate_secret                         = true

    token_validity_units {
        access_token    = "minutes"
        id_token        = "hours"
        refresh_token   = "days"
    }
}

resource "aws_cognito_identity_provider" "google_provider" {
    user_pool_id    = aws_cognito_user_pool.cognito_user_pool.id
    provider_name   = "Google"
    provider_type   = "Google"

    provider_details = {
        authorize_scopes = "openid profile email"
        client_id        = var.GOOGLE_CLIENT_ID
        client_secret    = var.GOOGLE_CLIENT_SECRET
    }

    attribute_mapping = {
        name        = "name"
        email       = "email"
        given_name  = "given_name"
        family_name = "family_name"
    }

}