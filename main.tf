# ------------------------------------------------------------------------------
# privileges for the instance we are standing up
# ------------------------------------------------------------------------------
resource "aws_iam_role" "instance_connect" {
  name        = "instance-connect"
  description = "privileges for the instance-connect demonstration"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_connect" {
  role       = "${aws_iam_role.instance_connect.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "instance_connect" {
  name = "instance-connect"
  role = "${aws_iam_role.instance_connect.id}"
}

# ------------------------------------------------------------------------------
# security group constraining access
# ------------------------------------------------------------------------------

resource "aws_security_group" "instance_connect" {
  vpc_id      = "${data.aws_vpc.default.id}"
  name_prefix = "instance_connect"
  description = "allow ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.ssh_list}"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# the instance we will try to connect to
# ------------------------------------------------------------------------------
resource "aws_instance" "instance_connect" {
  ami                         = "${data.aws_ami.target_ami.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${data.aws_subnet.default.id}"
  associate_public_ip_address = true

  root_block_device = {
    volume_type = "standard"
    volume_size = 8
  }

  vpc_security_group_ids = ["${aws_security_group.instance_connect.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.instance_connect.name}"

  tags        = "${merge(map("Name","instance_connect"), var.tags)}"
  volume_tags = "${merge(map("Name","instance_connect"), var.tags)}"

  user_data = <<EOF
#!/bin/bash
yum update -y -q
yum install ec2-instance-connect
grep AuthorizedKeys /etc/ssh/sshd_config
EOF
}

# ------------------------------------------------------------------------------
# policy for users allowing connection
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "instance_connect" {
  name        = "instance-connect"
  path        = "/test"
  description = "Allows use of EC2 instance connect"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
  		"Effect": "Allow",
  		"Action": "ec2-instance-connect:SendSSHPublicKey",
  		"Resource": "${aws_instance.instance_connect.arn}",
  		"Condition": {
  			"StringEquals": { "ec2:osuser": "${var.test_user}" }
  		}
  	},
    ,
		{
			"Effect": "Allow",
			"Action": "ec2:DescribeInstances",
			"Resource": "*"
		}
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "instance_connect" {
  name       = "instance-connect"
  users      = ["${var.test_user}"]
  policy_arn = "${aws_iam_policy.instance_connect.arn}"
}
