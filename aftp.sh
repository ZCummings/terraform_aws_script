#!/bin/bash

# Requirements:
# 1 - You are running in a *nix or macOS environment
# 2 - AWS Command Line Tools (awscli) installed
# 3 - Terraform v0.11+ installed
# 4 - TFLint is installed (if on MacOS using homebrew -> 'brew tap wata727/tflint' then 'brew install tflint')
# 5 - There is a TerraformAdmin user in AWS that has full admin permissions along with an AWS Key and Secret. 
# 	  **NOTE**
#     I do not expect to see a full admin terraform user in the wild. Following general best practices would suggest 
#     we use TerraformBuilder and TerraformDestroyer roles that give a user the minimal necessary actions required to
#     perform the operations. 

# Prior to executing this script, please run 'chmod 775 aftp.sh'
# Execute this script using './aftp.sh'
# Please run 'terraform destroy' after you are finished in order to obliterate the infrastucture built by this script
# Failure to do so will lead to surprisingly high bills --> load balancers != cheap

echo "## Checking for dependencies ##"
# checks for AWS Command Line Tools, Terraform, and TFLint
command -v aws >/dev/null 2>&1 || { echo "AWS Command Line Tools are required but not installed.  Aborting. Please install the AWS Command Line Tools." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but it's not installed.  Aborting. Please install Terraform." >&2; exit 1; }
command -v tflint >/dev/null 2>&1 || { echo "TFLint is required but it's not installed.  Aborting. Please install TFLint." >&2; exit 1; }

echo "## Building something AWSome ##"
# look for an existing key and if not there, create one with the appropriate permissions
(ls ~/.ssh/zc_miniproject_key.pem >> /dev/null 2>&1 && echo "## Skipping key generation ##") || (echo "## Creating new key ##"; aws ec2 --region us-east-1 create-key-pair --key-name zc_miniproject_key --query 'KeyMaterial' --output text > ~/.ssh/zc_miniproject_key.pem; chmod 400 ~/.ssh/zc_miniproject_key.pem; echo "Key created in ~/.ssh with permissions set to 400")

echo "## Checking if ssh-agent is running ##"
# check is ssh-agent is running and if no, start ssh-agent then add the new key
(pgrep ssh-agent > /dev/null 2>&1 && echo "## ssh-agent is running ##") || (echo "## Starting ssh-agent ##"; eval `ssh-agent -s`; echo "##  Adding new key ##"; ssh-add ~/.ssh/zc_miniproject_key.pem)

echo "## Linting the Terraform templates ##"
# run TFLint against our templates to make sure our code follows best practices and to look for errors that cannot be detected by 'terraform plan' 
tflint

echo "## Testing the infrastucture with Inspec"


# assuming tflint produces no errors, execute 'terraform apply'
echo "##  Assembling the universe ##"
terraform init
terraform apply




