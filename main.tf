module "S3" {
    source = "./modules/S3"
    
    BUCKET_NAME                     = "styl-file-upload-download-bucket"
    CLOUDFRONT_OAC_NAME             = "Cloudfront-oac-test"

    S3_BUCKET_TAGS                  = {
        Name        = "styl-file-upload-download-S3-bucket"
        Environment = "Development"
    }
    
}

module "dynamoDB" {
    source          = "./modules/dynamoDB"
    
    TABLE_NAME      = "styl-file-upload-download-dynamoDB-table"
    READ_CAPACITY   = 5
    WRITE_CAPACITY  = 5

    DYNAMODB_TAGS   = {
        Name        = "dynamodb_table_file_data"
        Environment = "Development" 
    }

}

# Cloudfront Upload
module "cloudfront_flow_upload" {
    source                          = "./modules/cloudfront_flow"
    
    S3_BUCKET_REGIONAL_DOMAIN_NAME  = module.S3._S3_BUCKET_REGIONAL_DOMAIN_NAME
    S3_BUCKET_ID                    = module.S3._S3_BUCKET_ID
    CLOUDFRONT_OAC_ID               = module.S3._CLOUDFRONT_OAC_ID
    LAMBDA_EDGE_ARN                 = module.authentication_upload._LAMBDA_EDGE_ARN
    
    APIGW_NAME                      = "Cloudfront-APIGW-Upload"
    
    LAMBDA_FUNCTION_NAME            = "lamda_init_handler"
    LAMBDA_ROLE_NAME                = "role_apigw_lambda_S3_dynamodb_upload"
    LAMBDA_RUNTIME                  = "python3.11"
    
    DYNAMODB_TABLE_NAME             = module.dynamoDB._DYNAMODB_TABLE_NAME
    ROOT_WEBSITE                    = "upload.html"

    LAMBDA_TAGS                     = {
        Name        = "STYL Lambda Initiate Upload handler"
        Environment = "Development"
    }

    CLOUDFRONT_TAGS                 = {
        Name        = "STYL Cloudfront distribution Upload"
        Environment = "Development"
    }
}

# Cloudfront Download
module "cloudfront_flow_download" {
    source                          = "./modules/cloudfront_flow"
    
    S3_BUCKET_REGIONAL_DOMAIN_NAME  = module.S3._S3_BUCKET_REGIONAL_DOMAIN_NAME
    S3_BUCKET_ID                    = module.S3._S3_BUCKET_ID
    CLOUDFRONT_OAC_ID               = module.S3._CLOUDFRONT_OAC_ID
    LAMBDA_EDGE_ARN                 = module.authentication_download._LAMBDA_EDGE_ARN
    APIGW_NAME                      = "Cloudfront-APIGW-Download"
    
    LAMBDA_FUNCTION_NAME            = "lambda_utilize_token"
    LAMBDA_ROLE_NAME                = "role_apigw_lambda_S3_dynamodb_download"
    LAMBDA_RUNTIME                  = "python3.11"
    
    DYNAMODB_TABLE_NAME             = module.dynamoDB._DYNAMODB_TABLE_NAME
    ROOT_WEBSITE                    = "download.html"

    LAMBDA_TAGS                     = {
        Name        = "STYL Lambda Initiate Upload handler"
        Environment = "Development"
    }

    CLOUDFRONT_TAGS                 = {
        Name        = "STYL Cloudfront distribution Download"
        Environment = "Development"
    }
}

module "shared_policy" {
    depends_on = [ 
        module.cloudfront_flow_upload,
        module.cloudfront_flow_download
    ]
    
    source = "./modules/shared_policy"

    S3_BUCKET_NAME                          = module.S3._S3_BUCKET_NAME
    CLOUDFRONT_DISTRIBUTION_UPLOAD_ARN      = module.cloudfront_flow_upload._CLOUDFRONT_DISTRIBUTION_ARN
    CLOUDFRONT_DISTRIBUTION_DOWNLOAD_ARN    = module.cloudfront_flow_download._CLOUDFRONT_DISTRIBUTION_ARN
}

# Post upload handler
module "post_upload_handler" {
    source                          = "./modules/post_upload_handler"
    LAMBDA_FUNCTION_NAME            = "lambda_post_upload_handler"
    LAMBDA_ROLE_NAME                = "role_S3_lambda_dynamoDB_ses"
    LAMBDA_RUNTIME                  = "python3.11"
    
    DYNAMODB_TABLE_NAME             = module.dynamoDB._DYNAMODB_TABLE_NAME
    S3_BUCKET_ID                    = module.S3._S3_BUCKET_ID
    S3_BUCKET_ARN                   = module.S3._S3_BUCKET_ARN

    LAMBDA_TAGS                     = {
        Name        = "STYL Lambda Post Upload handler"
        Environment = "Development" 
    }
}

# Authentication upload
module "authentication_upload" {
    source                          = "./modules/authentication_upload"
    LAMBDA_FUNCTION_NAME            = "lambda_edge_validate_token_upload"
    LAMBDA_RUNTIME                  = "python3.11"
    LAMBDA_ARCHITECTURE             = "x86_64"
    LAMBDA_ROLE_NAME                = "role_lambda_edge_validate_token_upload"
    
    S3_BUCKET_NAME                  = module.S3._S3_BUCKET_NAME

    COGNITO_USER_POOL_NAME          = "UserPool STYL File Sharing"
    COGNITO_USER_POOL_DOMAIN        = "styl-filesharing"
    COGNITO_USER_POOL_CLIENT_NAME   = "STYL Filesharing client app"
    DOMAIN_NAME                     = module.cloudfront_flow_upload._CLOUDFRONT_DOMAIN
    GOOGLE_CLIENT_ID                = "186097746882-qn8ik43ol17aup99ehd2kk57pu4932vb.apps.googleusercontent.com"
    GOOGLE_CLIENT_SECRET            = "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"

    COGNITO_TAGS                    = {
        Name        = "STYL Filesharing Cognito UserPool"
        Environment = "Development" 
    }
}

# Authentication download
module "authentication_download" {
    source                          = "./modules/authentication_download"
    LAMBDA_FUNCTION_NAME            = "lambda_edge_validate_token_download"
    LAMBDA_RUNTIME                  = "python3.11"
    LAMBDA_ARCHITECTURE             = "x86_64"
    LAMBDA_ROLE_NAME                = "role_lambda_edge_validate_token_download"
    
    S3_BUCKET_NAME                  = module.S3._S3_BUCKET_NAME

    DYNAMODB_TABLE_NAME             = module.dynamoDB._DYNAMODB_TABLE_NAME
}