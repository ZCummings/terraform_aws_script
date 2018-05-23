# Stelligent Miniproject

## Zach Cummings

This project uses Terraform to build out simple infrastructure consisting of 
a VPC, an Internet Gateway, associated subnets and routing, security groups, an Elastic Load Balancer, and two EC2 instances running Amazon's flavor of Linux with Apache serving out a single index page which displays "Automation for the People" in plain text.

### Requirements:
1. You are running in a -nix or macOS environment
2. AWS Command Line Tools (*awscli*) installed
3. Terraform v0.11+ installed
4. TFLint is installed (if on MacOS using homebrew -> '*brew tap wata727/tflint*' then '*brew install tflint*')
5. There is a TerraformAdmin user in AWS that has full admin permissions along with an AWS Key and Secret.

### Instructions:
1. Create a user in IAM called *TerraformAdmin* and assign the *AdministratorAccess* to this user 
	*NOTE: I would not expect to use or create a full admin terraform user in the wild. Best practices would suggest 
	either we use TerraformBuilder and TerraformDestroyer policies that give a user the minimal necessary actions required to
	perform the operations, or create environment specific roles for a single TerraformUser account.*
2. Prior to executing this script, please run '*chmod 775 aftp.sh*'
3. Execute this script using '*./aftp.sh*'
4. The script will output the load balancer dns_name to the command line - please allow a few minutes for the servers to come up before curling that location.
5. Please run '*terraform destroy*' after you are finished in order to obliterate the infrastucture built by this script
	*NOTE: Failure to do so will lead to surprisingly high bills --> load balancers != cheap*

### Lessons Learned
1. Terraform is great for setting up infrastructure but trying to configure servers using "user data" or other methods is inefficient. 
2. The architecture here is very, very basic - but functional. Given more time with terraform, I would launch the instances into either an ASG (probably overkill) or 
	multiple subnets to isolate single points of failure make the system a little more robust. Given a little more time, there's probably a Docker/ECS solution. 
3. Creating a minimal IAM policy for Terraform appears to be challenging - and there's no clear winning strategy within the Terraform community. For now, ops account
	with env roles?
4. It's possible to apply TDD to Terraform (TestKitchen, Inspec, Goss for validation) but it wasn't something I could grok quickly and so I'm
	covering the test bases with TFLint - its a good place to start.