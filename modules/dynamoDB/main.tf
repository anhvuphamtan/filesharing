resource "aws_dynamodb_table" "dynamodb_table_file_data" {
    name            = var.TABLE_NAME
    billing_mode    = var.BILLING_MODE
    read_capacity   = var.READ_CAPACITY
    write_capacity  = var.WRITE_CAPACITY

    hash_key        = "id"
    attribute {
        name = "id"
        type = "S"
    }

    tags            = var.DYNAMODB_TAGS
}