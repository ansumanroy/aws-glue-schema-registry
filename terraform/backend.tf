terraform {
  backend "s3" {
    bucket  = "aws-glue-assets-651914028873-us-east-1"
    key     = "terraform/glue-schema-registry/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # Optional: Add DynamoDB table for state locking
    # dynamodb_table = "terraform-state-lock"
  }
}
