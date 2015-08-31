# AWS-SQLIO-Benchmark-Powershell
Powershell scripts to launch AWS EC2 Instances, install SQLIO, run benchmarks and store results in S3.
<br>
The intent is to test SQLIO performance based on the following variables:
<ul>
<li> EC2 Instance Type
<li> EBS Volume Type (either Provisioned IOPS SSD or General Purpose SSD)
</ul>
<b>Prereq's:</b>
<br>
These scripts should run from a machine running Powershell with the AWS Powershell toolkit installed and configured.
<br>
<hr>
<br>
<b>Usage Examples:</b>
<br>
<br>
<b>Example Usage 1:</b> 
<br>
Launch EC2 Instance with a Provisioned IOPS SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_IOPS.png">
<br>
<b>Example Usage 2:</b> 
<br>
Launch EC2 Instance with a General Purpose SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_GP2.png">
