variable "http_port" {
  description = "The port we will use for http requests (default = 80)"
  default = 80
}

variable "ssh_port" {
  description = "The port we will use for ssh (default = 22)"
  default = 22
}

variable "aws_region" {
	description = "The geographic area within AWS"
	default = "us-east-1"
}

variable "us-east-1a" {
	description = "The us-east-1a availibility zone"
	default = "us-east-1a"
}

variable "us-east-1b" {
	description = "The us-east-1b availibility zone"
	default = "us-east-1b"
}

variable "us-east-1c" {
	description = "The us-east-1c availibility zone"
	default = "us-east-1c"
}


variable "us-east-1d" {
	description = "The us-east-1d availibility zone"
	default = "us-east-1d"
}