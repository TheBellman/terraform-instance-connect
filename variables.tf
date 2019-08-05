# -----------------------------------------------------------------------------
# data lookups
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

data "aws_ami" "target_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20190618-x86_64-ebs"]
  }
}

data "aws_vpc" "default" {
  default = "true"
}

data "aws_subnet" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}
# -----------------------------------------------------------------------------
# items not likely to change much
# -----------------------------------------------------------------------------

variable "tags" {
  type = "map"
  default = {
    "Owner"   = "robert"
    "Project" = "instance-connect"
    "Client"  = "internal"
  }
}

/* variables to inject via terraform.tfvars */
variable "aws_region" {}
variable "aws_account_id" {}
variable "aws_profile" {}
variable "test_user" {}

# -----------------------------------------------------------------------------
# items that may change
# -----------------------------------------------------------------------------
variable "ssh_list" {
  type = "list"
  default = [ "83.240.144.127/32" ]
}
