terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-state-lock"
    bucket         = "terraform-state20190222125041734800000001"
    key            = "instance-connect"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/dcebdb94-dd79-4d33-b4f4-b00aee818b6d"
  }
}
