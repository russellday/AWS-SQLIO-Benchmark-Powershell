# AWS-SQLIO-Benchmark-Powershell
Powershell scripts to launch AWS EC2 Instances, install SQLIO, run benchmarks and store results in S3.
<br>
The intent is to test SQLIO performance based on the following variables:
<ul>
<li> EC2 Instance Type
<li> EBS Volume Type (either Provisioned IOPS SSD or General Purpose SSD)
</ul>
<b>Prerequisites:</b>
<br>
These scripts should run from a machine running Powershell with the AWS Powershell toolkit installed and configured.
