# EC2 Instance Connect demonstration

This project stands up a small instance to demonstrate the use of [EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html).

## Prequisites
It is assumed that:
 - appropriate AWS credentials are available
 - an up to date (at least 1.6.211) version of the AWS CLI is available.
 - terraform is available (this was developed with 0.11.11 and provider.aws v2.22.0)
 - an IAM user and associated profile is available for testing
 - the scripts are being run on a unix account.

## Usage
 - update `backend.tf` to specify your own Terraform backend
 - check `variables.tf` to see if there are values you want to change
 - create `terraform.tfvars` from `terraform.tfvars.template`
 - apply `terraform init` then `terraform apply`

On successful completion, information is reported that you may need:

```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

instance_ip = 35.176.206.59
subnet_cidr = 172.33.10.0/26
vpc_id = vpc-0c890c871b2f2edeb
```

Once the instance is up, you need to find it's ID, using the console or something like

```
aws --profile connect_test --region eu-west-2 ec2  describe-instances
```

If you have had a look at the [Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html) and added the Instance Connect client, then SSH is as simple as:

```
$ mssh -u connect_test i-08a1cb834f0c3f163
The authenticity of host '35.176.206.59 (35.176.206.59)' can't be established.
ECDSA key fingerprint is SHA256:9gXyv313j3gvjHfDk2Ou6wxlNb2ZKiJNcGAspdtafmg.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '35.176.206.59' (ECDSA) to the list of known hosts.

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
[ec2-user@ip-172-33-10-46 ~]$
```

This is equivalent to making your own temporary public/private key pair, sending it to the instance, then connecting with that key:

```
$ ssh-keygen -t rsa -f connect-test

$ aws ec2-instance-connect send-ssh-public-key \
  --profile connect_test \
  --region eu-west-2 \
  --instance-id i-08a1cb834f0c3f163 \
  --availability-zone eu-west-2a \
  --instance-os-user ec2-user \
  --ssh-public-key file://connect-test.pub

$ ssh -i connect-test ec2-35-176-206-59.eu-west-2.compute.amazonaws.com

$ rm connect-test connect-test.pub
```

## Implementation note
There are two things to note with this implementation. First, you may question why a VPC is created for the test. For me there are two reasons: I have locked down my default VPC to avoid accidental exposure of assets; and building a separate VPC is a good way for me to isolate assets for different projects. Second, I am attaching the required permissions to a user rather than a group. This is purely for convenience, and I recommend that in reality permissions are attached to groups, not users.

Be aware also that this instance has SSM enabled, so it can also be connected to via [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

## Teardown

To teardown the infrastructure, execute `terraform destroy`. This may take several minutes to execute as tearing down the VPC can be slow. If the tear down fails, you may need to re-execute the destroy command - Terraform can be poor at destroying VPC dependencies in the expected order. If re-executing fails, I'm afraid you may have to remove the VPC dependencies by hand and do a final `terraform destroy` to clean up.
