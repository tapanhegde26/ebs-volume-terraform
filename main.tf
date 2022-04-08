// Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myvm" {
  ami           = "ami-0b0af3577fe5e3532"
  instance_type = "t2.micro"
}

data "aws_ebs_volume" "ebs_volume" {
  most_recent = true

  filter {
    name   = "attachment.instance-id"
    values = ["${aws_instance.myvm.id}"]
  }
}

resource "aws_ebs_snapshot" "myvm_snapshot" {
  volume_id = data.aws_ebs_volume.ebs_volume.id

  tags = {
    Name = "myvm_snap"
  }
}



resource "aws_ebs_volume" "myvm_example" {
  availability_zone = "us-east-1a"
  snapshot_id       = aws_ebs_snapshot.myvm_snapshot.id
}

resource "aws_instance" "myvm2" {
  ami           = "ami-0b0af3577fe5e3532"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
}

resource "aws_volume_attachment" "myvm2-vol" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.myvm_example.id
  instance_id = aws_instance.myvm2.id
}

output "source_instance_id" {
  value = aws_instance.myvm.id
}

output "new_vol_id" {
  value = aws_ebs_volume.myvm_example.id
}

output "old_vol_id" {
  value = data.aws_ebs_volume.ebs_volume.id
}

output "ebs_snapshot_id" {
  value = aws_ebs_snapshot.myvm_snapshot.id
}

output "target_instance_id" {
  value = aws_instance.myvm2.id
}
