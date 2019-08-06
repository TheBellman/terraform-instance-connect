# ------------------------------------------------------------------------------
# define the VPC
# ------------------------------------------------------------------------------
resource "aws_vpc" "instance_connect" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(map("Name", "instance-connect"), var.tags)}"
}

# seal off the default NACL
resource "aws_default_network_acl" "instance_connect" {
  default_network_acl_id = "${aws_vpc.instance_connect.default_network_acl_id}"
  tags                   = "${merge(map("Name", "instance-connect-default"), var.tags)}"
}

# seal off the default security group
resource "aws_default_security_group" "instance_connect" {
  vpc_id = "${aws_vpc.instance_connect.id}"
  tags   = "${merge(map("Name", "instance-connect-default"), var.tags)}"
}

resource "aws_internet_gateway" "instance_connect" {
  vpc_id = "${aws_vpc.instance_connect.id}"
  tags   = "${merge(map("Name", "instance-connect-gateway"), var.tags)}"
}

# ------------------------------------------------------------------------------
# define the subnet
# ------------------------------------------------------------------------------
resource "aws_subnet" "instance_connect" {
  vpc_id                  = "${aws_vpc.instance_connect.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 10, 40)}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags                    = "${merge(map("Name", "instance-connect-public"), var.tags)}"
}

# ------------------------------------------------------------------------------
# route external traffic through the internet gateway
# ------------------------------------------------------------------------------
resource "aws_route_table" "instance_connect" {
  vpc_id = "${aws_vpc.instance_connect.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.instance_connect.id}"
  }

  tags = "${merge(map("Name", "instance-connect"), var.tags)}"
}

resource "aws_route_table_association" "instance_connect" {
  subnet_id      = "${aws_subnet.instance_connect.id}"
  route_table_id = "${aws_route_table.instance_connect.id}"
}

resource "aws_network_acl" "instance_connect" {
  vpc_id     = "${aws_vpc.instance_connect.id}"
  subnet_ids = ["${aws_subnet.instance_connect.id}"]
  tags       = "${merge(map("Name", "instance-connect"), var.tags)}"
}

# ------------------------------------------------------------------------------
# define NACL for the subnet
# ------------------------------------------------------------------------------
resource "aws_network_acl_rule" "ephemeral_out" {
  network_acl_id = "${aws_network_acl.instance_connect.id}"
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "http_out" {
  network_acl_id = "${aws_network_acl.instance_connect.id}"
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "https_out" {
  network_acl_id = "${aws_network_acl.instance_connect.id}"
  rule_number    = 102
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_in" {
  network_acl_id = "${aws_network_acl.instance_connect.id}"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "ssh_in" {
  network_acl_id = "${aws_network_acl.instance_connect.id}"
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
