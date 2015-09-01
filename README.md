# AWS-SQLIO-Benchmark-Powershell
Powershell scripts to automate the SQLIO benchmarking processing. Launch and AWS EC2 Instance, install and run SQLIO, send the results to S3. 
<br>
<br>
<b>OVERVIEW</b>
<br>
When running SQL server on AWS (either on RDS or hosting your own on EC2) you should carefully consider your storage options. The two options that provide optimal levels of performance and high availability are Provisioned IOPS SSD EBS volumes or General Purpose SSD EBS volumes.
<br>
<br>
The main differences between General Purpose and Provioned IOPs volumes are performance and cost. Provisioned IOP EBS volumes are designed to provide predictable and consistent performance. General Purpose SSD volumes are designed to provide a baseline of 3 IOPS per GB <a href="https://aws.amazon.com/blogs/aws/now-available-16-tb-and-20000-iops-elastic-block-store-ebs-volumes/" target="_blank">(more details)</a>. With this understanding, there are situations where you can actually achieve greater performance in terms of IOPS at a much lower cost by using General Purponse SSD volumes instead of Provisioned IOPS. For example, assume your 1 TB database needs around 8k IOPS. You could provision a 8k Provisioned IOPs 2 TB (room for logs and backup) volume at around $776/month or you could provision a larger (4TB) than needed General Purpose SSD volume (remember 3 IOPs/GB) and get more IOPS (max 10k) for about $406/month. Essentially, by over-provisioning the volume you can take advantage of the additional IOPS that come along with the increased volume size.
<br>
<br>
So how do we prove this theory? SQLIO Benchmarking is a good start. SQLIO is a benchmarking tool that tests disk subsystem performance for workloads consistent with SQL server. You can download SQLIO <a href="http://www.microsoft.com/en-us/download/details.aspx?id=20163">here</a> and this <a href="http://blogs.msdn.com/b/sqlmeditation/archive/2013/04/04/choosing-what-sqlio-tests-to-run-and-automating-sqlio-testing-somewhat.aspx">link</a> discusses how to run the tool and some additional considerations specific to SQL server.
<br>
<br>
These Powershell scripts are desinged to automate this SQLIO benchmarking process. Allowing you to specify the following as variables: EC2 Instance Type, EBS Volume Type (either Provisioned IOPS SSD or General Purpose SSD), and Volume Size. The scripts will launch and EC2 instance, create and attach and EBS volume, download and install SQLIO, run SQLIO, and place the results in S3.
<br>
<br>
Below is a visual representation of this automated process.
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIO_Process_Diagram.png">
<br>
<br>
The SQLIO Results from the scenario above are below, max latency took a small hit but the overall IOs/sec were much higher on the General Purpose EBS volumes. Not too bad for almost half the price.
<br>
<br>
<br>
<table>
<tr>
  <tr>
    <td colspan=2><b><u>Provisioned IOPS (8000) 2TB EBS Volume</u></b></td>
    <td colspan=2><b><u>General Purpose 4TB EBS Volume</u></b></td>
  </tr>
  <td>
    8 threads writing...<br>
    throughput metrics:<br>
    <b>IOs/sec:  8145.77</b><br>
    MBs/sec:    31.81<br>
    latency metrics:<br>
    Min_Latency(ms): 1<br>
    Avg_Latency(ms): 7<br>
    Max_Latency(ms): 99
  </td>
  <td>
    8 threads reading...<br>
    throughput metrics:<br>
    <b>IOs/sec:  8142.30</b><br>
    MBs/sec:    31.80<br>
    latency metrics:<br>
    Min_Latency(ms): 0<br>
    Avg_Latency(ms): 7<br>
    Max_Latency(ms): 82  
  </td>
  <td>
    8 threads writing...<br>
    throughput metrics:<br>
    <b>IOs/sec:  9758.89</b><br>
    MBs/sec:    38.12<br>
    latency metrics:<br>
    Min_Latency(ms): 1<br>
    Avg_Latency(ms): 6<br>
    Max_Latency(ms): 210
  </td>
  <td>
    8 threads reading...<br>
    throughput metrics:<br>
    <b>IOs/sec:  9802.78</b><br>
    MBs/sec:    38.29<br>
    latency metrics:<br>
    Min_Latency(ms): 0<br>
    Avg_Latency(ms): 6<br>
    Max_Latency(ms): 228
  </td>
</tr>
</table>
<b><u>General Purpose 4TB EBS Volume</u></b>
<br>
<table>
  <tr>
    <td>
      8 threads writing...<br>
      throughput metrics:<br>
      <b>IOs/sec:  9758.89</b><br>
      MBs/sec:    38.12<br>
      latency metrics:<br>
      Min_Latency(ms): 1<br>
      Avg_Latency(ms): 6<br>
      Max_Latency(ms): 210
    </td>
    <td>
      8 threads reading...<br>
      throughput metrics:<br>
      <b>IOs/sec:  9802.78</b><br>
      MBs/sec:    38.29<br>
      latency metrics:<br>
      Min_Latency(ms): 0<br>
      Avg_Latency(ms): 6<br>
      Max_Latency(ms): 228
    </td>
  <tr>
</table>
<br>
<b>PRE-REQ'S</b>
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
If you provide the ARN of an SNS topic configured for email, the process will send an email notification when the process completes. This is helpful, the full SQLIIO tests can take over an hour to complete.
<br>
<br>
<b>4. Create a IAM Role for the instnaces launched via the Powershell script.</b>
<br>
You will need to create an IAM role that grants the EC2 instance launched via the PowerShell scripts access to perform the following tasks:
<ul>
<li>Place the SQLIO results text file in a S3 bucket
<li>Publish a message to an SNS topic (Optional)
<li>Terminate the EC2 instance once the SQLIO testing is complete
</ul>
Your template will look similiar to the template below, you can download the template below <a href="https://s3.amazonaws.com/russell.day/SQLIO_EC2Instance_Policy.xml" target="_blank">here</a>.
<br>
<br>
<img src="https://s3.amazonaws.com/russell.day/SQLIO_InstancePolicyV2.png">
<br>
<hr>
<b>PARAMETERS</b>
<br>
Most of the parameters contain defaults to allow for running a quick test with mininal inputs. Use the guides below to customize the parameters based on your test objectives.
<br>
<br>
Replace the following parameters with your AWS specific values
<br>
<div class="highlight highlight-PowerShell">
<pre>
<span class="pl-c">$Region = "us-east-1" #Specify your desired AWS Region</span> 
<span class="pl-c">$SubnetId = "subnet-******" #Specify a VPC Public subnet</span> 
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



