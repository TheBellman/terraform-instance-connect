output "vpc_id" {
  value = "${aws_vpc.instance_connect.id}"
}

output "subnet_cidr" {
  value = "${aws_subnet.instance_connect.cidr_block}"
}

output "instance_ip" {
  value = "${aws_instance.instance_connect.public_ip}"
}
