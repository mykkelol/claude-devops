# Remote state backend using S3 + DynamoDB locking.
#
# HOW TO ENABLE:
#   1. On your first run, leave this block commented out and run:
#        terraform init
#        terraform apply
#      This creates all AWS resources including the S3 bucket and DynamoDB table
#      you intend to use for state storage (provision them separately or reuse
#      existing ones).
#
#   2. Once the state bucket and DynamoDB lock table exist, uncomment the block
#      below and fill in the correct bucket name, region, and table name.
#
#   3. Migrate local state to the remote backend:
#        terraform init -migrate-state
#
#   After migration, all subsequent plan/apply operations will use remote state.

# terraform {
#   backend "s3" {
#     bucket         = "claude-devops-production-tfstate"
#     key            = "production/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "claude-devops-production-tfstate-lock"
#     encrypt        = true
#   }
# }
