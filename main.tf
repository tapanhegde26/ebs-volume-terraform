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

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "myvm" {
  ami                    = "ami-0b0af3577fe5e3532"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = ["${aws_security_group.myvm_sec_grp.id}"]
  subnet_id              = aws_subnet.myvm_subnet.id
  user_data              = file("init-script.sh")
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
  ami                    = "ami-0b0af3577fe5e3532"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  key_name               = var.key_name
  vpc_security_group_ids = ["${aws_security_group.myvm_sec_grp.id}"]
  subnet_id              = aws_subnet.myvm_subnet.id
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
