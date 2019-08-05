output "vpc_id" {
  value = "${data.aws_vpc.default.id}"
}

output "subnet_cidr" {
  value = "${data.aws_subnet.default.cidr_block}"
}

output "instance_ip" {
  value = "${aws_instance.instance_connect.public_ip}"
}
