// Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "source_instance_id" {
  default = "i-0f73a837ea36544d2"
}

variable "target_instance_id" {
  default = "i-058752838122f71be"
}

provider "aws" {
  region = "us-east-1"
  profile = "personal"
}

//Get aws instance details
data "aws_instance" "source_instance" {
  instance_id = var.source_instance_id
}

//Get ebs volume attached to source instance
# data "aws_ebs_volume" "source_ebs_volume" {
#   most_recent = true
#   count = lengdata.aws_instance.source_instance.ebs_block_device
#   # filter {
#   #   name   = "volume-type"
#   #   values = ["gp2"]
#   # }

# }

output "source_instance" {
  value       = "${data.aws_instance.source_instance}"
  description = "Source EBS Volumes"
}

# locals {
#   sourcevolumes = [
#     for vol in data.aws_instance.source_instance.ebs_block_device: [
#          lookup( vol , "volume_id") 
#       ]
#   ] 
# }

# locals {
#   sourcevols = flatten(local.sourcevolumes)
# }
# output "source_volumes" {
#   value       = "${local.sourcevols}"
#   description = "Source EBS Volumes"
# }

//Create snapshot of volume for each SourceVolumes
resource "aws_ebs_snapshot" "myvm_snapshot" {
  for_each = { for volume in data.aws_instance.source_instance.ebs_block_device : volume.volume_id => volume }
  volume_id = each.value.volume_id
  tags = {
    SourceVolume =  each.value.volume_id
    SourceAvailabilityZone =  data.aws_instance.source_instance.availability_zone
  }
}


//Create clone of source volume using the Snapshot
resource "aws_ebs_volume" "clone_ebs_volume" {
  
  for_each = aws_ebs_snapshot.myvm_snapshot
  snapshot_id = each.value.id
  // Selecting the Availability Zone Automatically from the Source Volume
  availability_zone = lookup( each.value.tags_all , "SourceAvailabilityZone")
}

//Get aws target instance details
data "aws_instance" "target_instance" {
  instance_id = var.target_instance_id
}

locals {
  allowed_device_names = ["/dev/xvdba","/dev/xvdbb","/dev/xvdbc","/dev/xvdbd","/dev/xvdbe","/dev/xvdbf","/dev/xvdbg","/dev/xvdbh","/dev/xvdbi","/dev/xvdbj","/dev/xvdbk","/dev/xvdbl","/dev/xvdbm","/dev/xvdbn","/dev/xvdbo","/dev/xvdbp","/dev/xvdbq","/dev/xvdbr","/dev/xvdbs","/dev/xvdbt","/dev/xvdbu","/dev/xvdbv","/dev/xvdbw","/dev/xvdbx","/dev/xvdby","/dev/xvdbz","/dev/xvdca","/dev/xvdcb","/dev/xvdcc","/dev/xvdcd","/dev/xvdce","/dev/xvdcf","/dev/xvdcg","/dev/xvdch","/dev/xvdci","/dev/xvdcj","/dev/xvdck","/dev/xvdcl","/dev/xvdcm","/dev/xvdcn","/dev/xvdco","/dev/xvdcp","/dev/xvdcq","/dev/xvdcr","/dev/xvdcs","/dev/xvdct","/dev/xvdcu","/dev/xvdcv","/dev/xvdcw","/dev/xvdcx","/dev/xvdcy","/dev/xvdcz","/dev/sda","/dev/sdb","/dev/sdc","/dev/sdd","/dev/sde","/dev/sdf","/dev/sdg","/dev/sdh","/dev/sdi","/dev/sdj","/dev/sdk","/dev/sdl","/dev/sdm","/dev/sdn","/dev/sdo","/dev/sdp","/dev/sdq","/dev/sdr","/dev/sds","/dev/sdt","/dev/sdu","/dev/sdv","/dev/sdw","/dev/sdx","/dev/sdy","/dev/sdz"]
  taken_device_names = [
    for vol in data.aws_instance.source_instance.ebs_block_device: [
         lookup( vol , "device_name") 
      ]
  ]
  available_device_names = setsubtract(local.allowed_device_names, flatten(local.taken_device_names))
}

// Randomly take any device name from the available device Names
resource "random_shuffle" "dvcname"{
  input = local.available_device_names
}

// Try to get the Available Device Names
// Device Names have standards check here https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html 

# locals {
#   ebsvols = [
#     for vol in aws_ebs_volume.clone_ebs_volume : [
#       for i in range(1, length(aws_ebs_volume.clone_ebs_volume)+1): {
#           device_name = random_shuffle.dvcname.result[i]
#           volume_id = vol.id
#       } 
#     ]
#   ]
# }

# # 
# locals {
#   targetebs = flatten(local.ebsvols)
# }

//Attach cloned volume to target instance 
// For Externally attached Volumes with aws_volume_attachment . Delete on Termination would be NO. so need manual deletion
 resource "aws_volume_attachment"  "ebsvol"{
  for_each  = aws_ebs_volume.clone_ebs_volume
  device_name = random_shuffle.dvcname.result[index(keys(aws_ebs_volume.clone_ebs_volume), each.key)]
  volume_id = each.value.id
  instance_id = data.aws_instance.target_instance.id
  
}


# resource "aws_volume_attachment"  "ebsvol"{
#   count=length(aws_ebs_volume.clone_ebs_volume)
#   device_name = random_shuffle.dvcname.result[count.index]
#   volume_id = aws_ebs_volume.clone_ebs_volume.id
#   instance_id = data.aws_instance.target_instance.id
# }
