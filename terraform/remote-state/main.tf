# Create S3 bucket for remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "oldebreeze-terraform-state"
  
  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_state_locks" {
  name           = "terraform-state-locks"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create IAM user for remote state access
resource "aws_iam_user" "terraform" {
  name = "terraform"
}

# Create IAM policy for remote state access
resource "aws_iam_policy" "terraform_state_access" {
  name        = "terraform"
  description = "Terraform policy for remote state access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowFullAccessToBucket",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::oldebreeze-terraform-state",
        "arn:aws:s3:::oldebreeze-terraform-state/*"
      ]
    },
    {
      "Sid": "AllowListObjectsInBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::oldebreeze-terraform-state"
      ],
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "terraform.tfstate*"
          ]
        }
      }
    },
    {
      "Sid": "AllowDynamoDBTable",
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-locks"
      ]
    }
  ]
}
EOF
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "terraform" {
  user       = "${aws_iam_user.terraform.name}"
  policy_arn = "${aws_iam_policy.terraform_state_access.arn}"
}

# Create IAM access key for user
resource "aws_iam_access_key" "terraform" {
  user = "${aws_iam_user.terraform.name}"
}