#!/bin/bash

ssh-keygen -t rsa -f connect-test

aws ec2-instance-connect send-ssh-public-key \
  --profile connect_test \
  --region eu-west-2 \
  --instance-id i-0d89e0ce84bd7a9a5 \
  --availability-zone eu-west-2a \
  --instance-os-user ec2-user \
  --ssh-public-key file://connect-test.pub

ssh -i connect-test ec2-user@ec2-18-130-243-120.eu-west-2.compute.amazonaws.com

rm connect-test connect-test.pub
