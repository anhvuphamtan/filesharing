variable "TABLE_NAME" {
    type = string 
}

variable "READ_CAPACITY" {
    type = number
}

variable "WRITE_CAPACITY" {
    type = number    
}

variable "BILLING_MODE" {
    type    = string
    default = "PROVISIONED" 
}

variable "DYNAMODB_TAGS" {
    type    = map(string)
}