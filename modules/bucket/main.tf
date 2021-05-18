/*
resource "aws_s3_bucket" "tf_state" {
  bucket    = var.bucket

  # Enable versioning so you can see the full revision history of state files
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
*/

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"  
  
  attribute {
    name = "LockID"
    type = "S"
  }
}