
# Provider definition - using AWS
provider "aws" {
    region = "us-east-1"
    access_key = "AKIAJMP3NTFGMOUVBO4Q"
    secret_key = "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"
}

# Creates a VPC for our miniproject instance(s)
resource "aws_vpc" "miniproject" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "miniproject-vpc"
  }
}

# Creates an internet gateway for our VPC
resource "aws_internet_gateway" "miniproject" {
  vpc_id = "${aws_vpc.miniproject.id}"
  tags {
    Name = "miniproject-igw"
  }
}

# Creates a subnet for our instance(s)
resource "aws_subnet" "subnet" {
	cidr_block = "10.0.1.0/24"
	map_public_ip_on_launch = true
	vpc_id = "${aws_vpc.miniproject.id}"
}

# Sets up routing table from VPC to the internet gateway
resource "aws_route" "route" {
	route_table_id = "${aws_vpc.miniproject.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.miniproject.id}"
}

# Creates a security group for an elastic load balancer
resource "aws_security_group" "miniproject_elb_sg" {
  name = "miniproject-elb-sg"
  vpc_id = "${aws_vpc.miniproject.id}"

  ingress {
    protocol    = "tcp"
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creates a security group for our instance(s)
resource "aws_security_group" "miniproject-sg" {
  name = "miniproject-sg"
  vpc_id = "${aws_vpc.miniproject.id}"

  # note to self - alter ssh access

  ingress {
    protocol    = "tcp"
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creates an IAM role for our instances
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Create our EC2 instance(s) using an Amazon Linux AMI
resource "aws_instance" "miniproject-ec2" {
    ami = "ami-467ca739"
    count = "2"
    security_groups = ["${aws_security_group.miniproject-sg.id}"]
    subnet_id = "${aws_subnet.subnet.id}"
    iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd stress -y
                cd /var/www/html
                echo "healthy" > healthy.html
                echo "Created using Terraform. Tested using TFLint and Inspec." > index.html
                service httpd start
                chkconfig httpd on &
                EOF

    instance_type = "t2.micro"
    key_name      = "zc_miniproject_key"
    tags {
        Name = "Stelligent Miniproject"
        Owner = "Zach Cummings"
    }

  connection {
    user         = "ec2-user"
    private_key  = "${file("~/.ssh/zc_miniproject_key.pem")}"
  }
}

# Creates an elastic load balancer
resource "aws_elb" "miniproject_elb" {
  name = "miniproject-elb"
  security_groups = ["${aws_security_group.miniproject_elb_sg.id}"]
  subnets = ["${aws_subnet.subnet.*.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    target = "HTTP:80/healthy.html"
    interval = 5
    timeout = 3
  }

  instances = ["${aws_instance.miniproject-ec2.*.id}"]


}

output "dns" {
  value = "${aws_elb.miniproject_elb.dns_name}"
}
