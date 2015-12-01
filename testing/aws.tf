provider "aws" {
  region = "us-east-1"
}

module "aws-drone-testing" {
  source = "./terraform/aws"
  availability_zone = "us-east-1e"
  ssh_username = "centos"
  source_ami = "ami-61bbf104"
  short_name = "drone"
  long_name = "ciscocloud-drone-ci"

  control_count = 3
  worker_count = 3
  edge_count = 2
}
