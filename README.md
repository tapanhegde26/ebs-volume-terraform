# ebs-volume-terraform
create ebs volume and snapshot and attach same to ec2 instance using terraform script

This script will do following

* Creates EC2 instance(source) with EBS volume attached
* Creates snapshot of that EBS volume
* Creates separate new volume from snapshot (previously created)
* Attach this cloned new volume to EC2 instance (Target)

On successfull run of above script will yield following resources in your AWS account

1. 2 EC2 instances - Source, Target
2. 3 EBS volumes - Attached 2 volumes to source
                 - Attached 1 volume to target
3. 1 snapshot
