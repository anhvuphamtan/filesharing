# ---------------------------------------------- Data ---------------------------------------------- #
data "aws_caller_identity" "aws_account" {}

data "archive_file" "lambda_zip_file" {
    type            = "zip"
    source_file     = "${path.module}/../../data/src/${var.LAMBDA_FUNCTION_NAME}.py"
    output_path     = "${path.module}/../../data/zip/${var.LAMBDA_FUNCTION_NAME}.zip"
}

# --------------------------------------------------------------------------------------------------- #





# ---------------------------------------------- Lamda ---------------------------------------------- #
resource "aws_lambda_function" "lambda_trigger" {
    function_name       = var.LAMBDA_FUNCTION_NAME
    filename            = data.archive_file.lambda_zip_file.output_path
    handler             = "${var.LAMBDA_FUNCTION_NAME}.lambda_handler"
    source_code_hash    = filebase64sha256(data.archive_file.lambda_zip_file.output_path)
    runtime             = var.LAMBDA_RUNTIME
    architectures       = [var.LAMBDA_ARCHITECTURE]
    
    role                = aws_iam_role.iam_role_apigw_lambda_S3_dynamodb.arn
    tags                = var.LAMBDA_TAGS
}

resource "aws_iam_role" "iam_role_apigw_lambda_S3_dynamodb" {
    name = var.LAMBDA_ROLE_NAME
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_apigw_lambda_S3_dynamodb" {
    name    = "policy_${var.LAMBDA_ROLE_NAME}"
    role    = aws_iam_role.iam_role_apigw_lambda_S3_dynamodb.id
    policy  = <<EOF
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
            "Resource": [
                "arn:aws:logs:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda_trigger.function_name}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:table/${var.DYNAMODB_TABLE_NAME}"
            ]
        }
    ]
}
EOF 
}

resource "aws_lambda_permission" "apigw_permission_lambda" {
    statement_id    = "Allow-APIGateway-Invoke"
    action          = "lambda:InvokeFunction"
    function_name   = aws_lambda_function.lambda_trigger.function_name
    principal       = "apigateway.amazonaws.com"

    source_arn      = "${aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.execution_arn}/*/POST/api/items"
}
# --------------------------------------------------------------------------------------------------------- #





# ---------------------------------------------- API Gateway ---------------------------------------------- #
resource "aws_apigatewayv2_api" "cloudfront_api_gatewayv2_lambda" {
    name            = var.APIGW_NAME
    protocol_type   = "HTTP"
    tags            = var.APIGW_TAGS
}

resource "aws_apigatewayv2_integration" "apigw_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda_trigger.arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "apigw_route" {
  api_id        = aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id
  route_key     = "POST /api/items"
  target        = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "apigw_deploy_stage" {
  api_id        = aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id
  auto_deploy   = true
  name          = "dev"
  tags          = var.APIGW_TAGS
}

# ---------------------------------------------------------------------------------------------------------#





# ---------------------------------------------- Cloudfront ---------------------------------------------- #
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
    depends_on                      = [ 
        var.CLOUDFRONT_OAC_ID
    ]

    enabled                         = true 
    default_root_object             = var.ROOT_WEBSITE

    # -------------- S3 origin & cache behavior -------------- #
    origin {
        origin_access_control_id    = var.CLOUDFRONT_OAC_ID
        origin_id                   = var.S3_BUCKET_ID
        domain_name                 = var.S3_BUCKET_REGIONAL_DOMAIN_NAME
    }

    default_cache_behavior {
        allowed_methods             = ["GET", "HEAD"]
        cached_methods              = ["GET", "HEAD"]
        target_origin_id            = var.S3_BUCKET_ID
    
        cache_policy_id             = var.CACHE_POLICY
        viewer_protocol_policy      = "allow-all"

        # Lambda@edge view-request
        lambda_function_association {
            event_type          = "viewer-request"
            include_body        = true
            lambda_arn          = var.LAMBDA_EDGE_ARN
        }
    }



    # -------------- AWS API Gateway & cache behavior -------------- #
    origin {
        domain_name = "${aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id}.execute-api.${var.REGION}.amazonaws.com"
        origin_id   = aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id
        origin_path = "/dev"  
        
        custom_origin_config {
            http_port               = "80"
            https_port              = "443"
            origin_protocol_policy  = "https-only" 
            origin_ssl_protocols    = ["TLSv1.2"]
        }
    }

    ordered_cache_behavior {
        path_pattern            = "/api/*"
        allowed_methods         = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
        cached_methods          = ["GET", "HEAD"]
        target_origin_id        = aws_apigatewayv2_api.cloudfront_api_gatewayv2_lambda.id

        forwarded_values {
            query_string    = true
            headers         = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
            cookies {
                forward = "none"
            }
        }
    
        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 0
        max_ttl                = 0

        # Lambda@edge view-request
        lambda_function_association {
            event_type          = "viewer-request"
            include_body        = true
            lambda_arn          = var.LAMBDA_EDGE_ARN
        }
    }

    ordered_cache_behavior {
        path_pattern                = "/auth"
        allowed_methods             = ["GET", "HEAD"]
        cached_methods              = ["GET", "HEAD"]

        target_origin_id            = var.S3_BUCKET_ID

        forwarded_values {
            query_string = false
            cookies {
                forward  = "none"
            }
        }

        viewer_protocol_policy  = "allow-all"
        min_ttl                 = 0
        default_ttl             = 0
        max_ttl                 = 0

        # Lambda@edge view-request
        lambda_function_association {
            event_type          = "viewer-request"
            include_body        = true
            lambda_arn          = var.LAMBDA_EDGE_ARN
        }
    }   

    restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
    
    tags = var.CLOUDFRONT_TAGS
}