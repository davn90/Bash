#!/bin/bash

####################
# Author: Dawid
# Date: 17th-Feb-2024

# Version: v1
#
# THis script will report the AWS resource usage
#####################

set -x

# AWS S3
# AWS EC2
# AWS Lambda
# AWS IAM Users

# list s3 buckets
echo "Print list of s3 buckets"
aws s3 ls > resource

# list EC2 instances
echo "Print list of EC2 instances"
aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId' >> resource

# list lambda functions
echo "Print list of lambda functions"
aws lambda list-functions >> resource

# lis IAM Users
echo "Print list of IAM users"
aws iam list-users >> resource
