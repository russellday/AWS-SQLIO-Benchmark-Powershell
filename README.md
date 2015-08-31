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
<img src="https://s3.amazonaws.com/russell.day/SQLIO_EC2_POLICY.png">
<br>
<hr>
<b>PARAMETERS:</b>
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
You will need to create an IAM role that grants the EC2 instance the scripts launch access to perform a few tasks:
<ul>
<li>Place the SQLIO results in an S3 bucket
<li>TODO
<li>Terminate the EC2 instance once the SQLIO testing is complete
</ul>
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_GP2.png">
