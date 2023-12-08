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

    role            = aws_iam_role.iam_role_lambda_edge_download.arn
    timeout         = 5 
    publish         = true
    
}

resource "aws_iam_role" "iam_role_lambda_edge_download" {
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

resource "aws_iam_role_policy" "iam_policy_lambda_edge_download" {
    name = "policy_${var.LAMBDA_ROLE_NAME}"
    role = aws_iam_role.iam_role_lambda_edge_download.id
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
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:GetItem"
            ],
            "Resource": "arn:aws:dynamodb:${var.REGION}:${data.aws_caller_identity.aws_account.account_id}:table/${var.DYNAMODB_TABLE_NAME}"
        }
    ]
}
EOF
}

# --------------------------------------------------------------------------------------------------------- #