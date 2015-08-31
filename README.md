# AWS-SQLIO-Benchmark-Powershell
Powershell scripts to launch AWS EC2 Instances, install SQLIO, run benchmarks and store the results in S3.
<br>
<br>
<b>OVERVIEW:</b>
<br>
These Powershell scripts are desinged to automate SQLIO benchmarking AWS EBS volumes with the following varaibles:
<ul>
<li> EC2 Instance Type
<li> EBS Volume Type (either Provisioned IOPS SSD or General Purpose SSD)
<li> Volume Size
</ul>
<b>PRE-REQ'S:</b>
<br>
<br>
<b>1. Configure Powershell environment with AWS Tools for Powershell</b>
These scripts should run from a machine running Powershell with the AWS Powershell toolkit installed and configured. <br>
Instructions for getting your Powershell environment up and running with AWS Tools for Powershell can be found here: http://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html.
<br>
<br>
<b>2. Create an S3 bucket to store the SQLIO benchmark results.</b>
<br>
You will need to create a bucket in S3 to store the output of the SQLIO.exe. It is helpful to keep the results of these benchmarks on hand for future reference.
<br>
<br>
<b>3. Create an SNS topic to receive email notification when process completes (Optional Step)</b>
<br>
This step is optional, but if you provide the ARN to a SNS topic the process will send an email notification when the process completes. This is helpful, the SQLIIO tests can take over an hour to complete.
<br>
<br>
<b>4. Create a IAM Role for the instnaces launched via the Powershell script.</b>
<br>
You will need to create an IAM role that grants the EC2 instance the scripts launch access to perform a few tasks:
<ul>
<li>Place the SQLIO results in an S3 bucket
<li>Publish a message to an SNS topic (Optional)
<li>Terminate the EC2 instance once the SQLIO testing is complete
</ul>
Your template will look similiar to the template below, you can download the template below <a href="https://s3.amazonaws.com/russell.day/SQLIO_EC2Instance_Policy.xml" target="_blank">here</a>.
<br>
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIO_EC2_POLICY.png">
<br>
<hr>
<b>PARAMETERS:</b>
<br>
  [Parameter(Mandatory=$false)][string] $InstanceType = "m3.large",
  [Parameter(Mandatory=$false)][string] $KeyPairName = "aws_20150520",
  [Parameter(Mandatory=$false)][string] $Region = "us-east-1",	
	[Parameter(Mandatory=$false)][string] $SecurityGroup = "sg-076e8a60",
	[Parameter(Mandatory=$false)][string] $SubnetId = "subnet-42773535",
	[Parameter(Mandatory=$false)][string] $TagName = "SQLIO Benchmark",
	[Parameter(Mandatory=$true)][int32] $VolumeSizeGiB, 
	[Parameter(Mandatory=$true)][int32] $TestFileSizeGB, 
	[Parameter(Mandatory=$true)][int32] $IOPS, 	
	[Parameter(Mandatory=$false)][string] $VolumeType = "gp2",
	[Parameter(Mandatory=$false)][string] $S3ResultsBucketName = "sqlioresults",
	[Parameter(Mandatory=$false)][string] $SNSTopic = "arn:aws:sns:****", #Optional: Include if you would like to be notified on completion
	[Parameter(Mandatory=$false)][string] $InstanceProfile = "arn:aws:iam::*****",
  [Parameter(Mandatory=$false)][string] $UserScript = (Join-Path $script:moduledirectory "SQLIOBootstrap.ps1"),
	[Parameter(Mandatory=$false)][Bool] $Fast = $false #Only run the 4k read and write tests
<br>
<b>USAGE EXMAMPES:</b>
<br>
<br>
<b>Example Usage 1:</b> 
<br>
Launch EC2 Instance with a Provisioned IOPS SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_IOPS_v2.png">
<br>
<b>Example Usage 2:</b> 
<br>
Launch EC2 Instance with a General Purpose SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_GP2.png">
