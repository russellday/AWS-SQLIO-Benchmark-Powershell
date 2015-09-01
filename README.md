# AWS-SQLIO-Benchmark-Powershell
Powershell scripts to automate SQLIO benchmarking. Launch AWS EC2 Instances, install and run SQLIO, send the results to S3. 
<br>
<br>
<b>OVERVIEW</b>
<br>
When considering running SQL server on AWS (either RDS or rolling your own via EC2) you should carefully consider your storage options. The two options that provide good levels of performance and high availability are Provisioned IOPS SSD EBS volumes or General Purpose SSD EBS volumes.
<br>
<br>
The main differences between General Purpose and Provioned IOPs volumes are performance and cost. General Purpose SSD volumes are designed to provide a baseline of 3 IOPS per GB <a href="https://aws.amazon.com/blogs/aws/now-available-16-tb-and-20000-iops-elastic-block-store-ebs-volumes/" target="_blank">(more details)</a>. With this understanding, there are situations where you can actually get a relatively high performance volume in terms of IOPS at a much lower price point by using General Purponse SSD volumes instead of Provisioned IOPS. For example, assume your 1 TB database needs around 8000 IOPS. You could provision a 8000 Provisioned 2 TB (room for logs and backup) IOPS volume at around $776/month or you could provision a larger (4TB) than needed General Purpose SSD volume (remember 3 IOPs/GB) and get more IOPS for about $406/month. Essentially, we are assming by over-provisioning our volume we can take advantage of the additional IOPS that come along with the additional volume size.
<br>
<br>
So how do we prove this theory? SQLIO Benchmarking is a good start. SQLIO is a benchmarking tool that tests disk subsystem performance for workloads consistent with SQL server. You can download SQLIO <a href="http://www.microsoft.com/en-us/download/details.aspx?id=20163">here</a> and this <a href="http://blogs.msdn.com/b/sqlmeditation/archive/2013/04/04/choosing-what-sqlio-tests-to-run-and-automating-sqlio-testing-somewhat.aspx">link</a> discusses how to run the tool and some additional considerations specific to SQL server.
<br>
<br>
These Powershell scripts are desinged to automate this SQLIO benchmarking process. Allowing you to specify the following items a variables. The scripts will launch the EC2 servers, create and attache the EBS volume, download and install SQLIO, run SQLIO, and finally, place the results in S3.
<ul>
<li> EC2 Instance Type
<li> EBS Volume Type (either Provisioned IOPS SSD or General Purpose SSD)
<li> Volume Size
</ul>
A visual of this automated process is below.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIO_Process_Diagram.png">
<br>
8 threads writing for 360 secs to file d:\TestFile.DAT using 4KB random IOs enabling multiple I/Os per thread with 8 outstanding buffering set to use hardware disk cache (but not file cache)<br>
IOs/sec:  8145.77<br>
Min_Latency(ms): 1<br>
Avg_Latency(ms): 7<br>
Max_Latency(ms): 99<br>
....
<br>
<b>PRE-REQ'S</b>
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
<b>PARAMETERS</b>
<br>
Most of the parameters contain defaults. To allow for running a quick test with mininal inputs. Use the guides below to customize the parameters based on your test goals.
<br>
Replace the following parameters with your AWS specific values
<br>
<div class="highlight highlight-PowerShell">
<pre>
<span class="pl-c">$KeyPairName = "aws_20150520" #Only required if you might need to log in to the instance to debug.</span>
<span class="pl-c">$Region = "us-east-1"</span>
<span class="pl-c">$SecurityGroup = "sg-076e8a60"</span>
<span class="pl-c">$S3ResultsBucketName = "sqlioresults"</span>
<span class="pl-c">$SNSTopic = "arn:aws:sns:****" #Optional</span>
<span class="pl-c">$InstanceProfile = "arn:aws:iam::*****"</span>
</pre>
</div>
Replace the following parameters with your desired test defaults
<br>
<div class="highlight highlight-PowerShell">
<pre>
<span class="pl-c">$InstanceType = "m3.large"</span>
<span class="pl-c">$TagName = "SQLIO Benchmark" #Name tag value</span>
<span class="pl-c">$VolumeType = "gp2" #either gp2 or io1</span>
<span class="pl-c">$Fast = $false #Only run the 4k read and write tests</span>
</pre>
</div>
Replace the following required parameters with your test values when prompted
<br>
<div class="highlight highlight-PowerShell">
<pre>
<span class="pl-c">$VolumeSizeGiB = Integer value between 4 (4 GiB) and 16384 (16 TB)</span>
<span class="pl-c">$TestFileSizeGB = Integer value between 10 (10 GB) and 9000 (9TB)</span> 
<span class="pl-c">$IOPS = For $VolumeType = io1, integer value between 100 and 20000 else ($VolumeType=gp2) blank</span>
</pre>
</div>
<b>Example Usage 1</b> 
<br>
Launch EC2 Instance with a Provisioned IOPS SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_IOPS_v2.png">
<br>
<b>Example Usage 2</b> 
<br>
Launch EC2 Instance with a General Purpose SSD EBS Volume.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIOBenchmark_Example_Usage_GP2.png">



