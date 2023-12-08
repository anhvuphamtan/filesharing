# ---------------------------------------------- Data ---------------------------------------------- #
data "aws_caller_identity" "aws_account" {}

data "archive_file" "lambda_zip_file" {
    type            = "zip"
    source_file     = "${path.module}/../../data/src/${var.LAMBDA_FUNCTION_NAME}.py"
    output_path     = "${path.module}/../../data/zip/${var.LAMBDA_FUNCTION_NAME}.zip"
}
# --------------------------------------------------------------------------------------------------- #

# ---------------------------------------------- Lambda ---------------------------------------------- #
resource "aws_lambda_function" "lambda_trigger" {
    function_name       = var.LAMBDA_FUNCTION_NAME
    filename            = data.archive_file.lambda_zip_file.output_path
    handler             = "${var.LAMBDA_FUNCTION_NAME}.lambda_handler"
    source_code_hash    = filebase64sha256(data.archive_file.lambda_zip_file.output_path)
    runtime             = var.LAMBDA_RUNTIME
    architectures       = [var.LAMBDA_ARCHITECTURE]
    
    role                = aws_iam_role.iam_role_S3_lambda_dynamoDB_ses.arn
    tags                = var.LAMBDA_TAGS
}

resource "aws_iam_role" "iam_role_S3_lambda_dynamoDB_ses" {
    name                = var.LAMBDA_ROLE_NAME 
    assume_role_policy  = <<EOF
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

resource "aws_iam_role_policy" "iam_policy_S3_lambda_dynamoDB_ses" {
    name            = "policy_${var.LAMBDA_ROLE_NAME}"
    role            = aws_iam_role.iam_role_S3_lambda_dynamoDB_ses.id
    policy          = <<EOF
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
            "Resource": "arn:aws:logs:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda_trigger.function_name}:*"
        },
    
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:GetItem",
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:table/${var.DYNAMODB_TABLE_NAME}"
        }
    ]
}
EOF

}

resource "aws_s3_bucket_notification" "S3_notification_lambda" {
    bucket = var.S3_BUCKET_ID

    lambda_function {
        lambda_function_arn = aws_lambda_function.lambda_trigger.arn
        events              = [
            "s3:ObjectCreated:*",
            "s3:ObjectRemoved:*"
        ]
    }
}

resource "aws_lambda_permission" "S3_permission_lambda" {
    statement_id    = "Allow-S3-Invoke"
    action          = "lambda:InvokeFunction"
    function_name   = aws_lambda_function.lambda_trigger.function_name
    principal       = "s3.amazonaws.com"

    source_arn      = var.S3_BUCKET_ARN
  
}

# ---------------------------------------------------------------------------------------------------- #
