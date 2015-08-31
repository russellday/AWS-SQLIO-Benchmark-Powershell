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
<div class="highlight highlight-PowerShell">
<pre>
<span class="pl-c"># AWS SDK Path </span>
<span class="pl-c1">Add-Type</span> <span class="pl-k">-</span>Path <span class="pl-s">"test...</span>
</pre>
</div>
<br>
<code>
$InstanceType = "m3.large",
$KeyPairName = "aws_20150520", #Only required if you might need to log in to the instance to debug.
$Region = "us-east-1",
$SecurityGroup = "sg-076e8a60",
$SubnetId = "subnet-42773535",
$TagName = "SQLIO Benchmark",
[Parameter(Mandatory=$true)][int32] $VolumeSizeGiB, 
[Parameter(Mandatory=$true)][int32] $TestFileSizeGB, 
[Parameter(Mandatory=$true)][int32] $IOPS, 
[Parameter(Mandatory=$false)][string] $VolumeType = "gp2", 
[Parameter(Mandatory=$false)][string] $S3ResultsBucketName = "sqlioresults", 
$SNSTopic = "arn:aws:sns:****", #Optional
$InstanceProfile = "arn:aws:iam::*****", 
$UserScript = (Join-Path $script:moduledirectory "SQLIOBootstrap.ps1"), 
$Fast = $false #Only run the 4k read and write tests 
</code>
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
<br>
<article class="markdown-body entry-content" itemprop="mainContentOfPage"><h1><a id="user-content-powershell-scripts-for-ec2-backups" class="anchor" href="#powershell-scripts-for-ec2-backups" aria-hidden="true"><span class="octicon octicon-link"></span></a>PowerShell Scripts for EC2 Backups</h1>

<p>A set of Windows PowerShell scripts to enable automated daily/weekly backups (via snapshots) on AWS EC2 Windows instances.  I used these to setup a backup process on Windows Server 2012 R2.</p>

<h2><a id="user-content-credit" class="anchor" href="#credit" aria-hidden="true"><span class="octicon octicon-link"></span></a>Credit</h2>

<p>First and foremost, credit for the original versions of these goes to Chris Hettinger from the following post:</p>

<p><a href="http://messor.com/aws-disaster-recovery-automation-w-powershell/">AWS Disaster Recovery Automation w/ Powershell</a></p>

<h2><a id="user-content-changes" class="anchor" href="#changes" aria-hidden="true"><span class="octicon octicon-link"></span></a>Changes</h2>

<p>However, the scripts presented in Chris' post use v1.0 of the AWS API, which is now deprecated.  I dusted off the 'ol API documents &amp; debugger to get them working with the current (as of April 2015) v2.3.33.0.</p>

<p>For the sake of completeness, I'm going to include the steps Chris outlined in his blog.</p>

<h2><a id="user-content-installation" class="anchor" href="#installation" aria-hidden="true"><span class="octicon octicon-link"></span></a>Installation</h2>

<h3><a id="user-content-1--setup-amazon-simple-email-service" class="anchor" href="#1--setup-amazon-simple-email-service" aria-hidden="true"><span class="octicon octicon-link"></span></a>1.  Setup Amazon Simple Email Service</h3>

<p>The first thing you will want to do is apply for access to SES and setup a verified sender address; this may take several hours.</p>

<h3><a id="user-content-2--get-the-aws-sdk-for-net" class="anchor" href="#2--get-the-aws-sdk-for-net" aria-hidden="true"><span class="octicon octicon-link"></span></a>2.  Get the AWS SDK for .NET</h3>

<p>Download the <a href="http://aws.amazon.com/sdkfornet/">AWS SDK for .NET</a></p>

<h3><a id="user-content-3--install-the-scripts" class="anchor" href="#3--install-the-scripts" aria-hidden="true"><span class="octicon octicon-link"></span></a>3.  Install the scripts</h3>

<p>After the SDK has been installed, pick a place to store the scripts (ex. C:\AWS). Next, copy the scripts into your AWS directory. Additionally, create a directory called “Logs” inside of your AWS directory.</p>

<h2><a id="user-content-configuration" class="anchor" href="#configuration" aria-hidden="true"><span class="octicon octicon-link"></span></a>Configuration</h2>

<h3><a id="user-content-configure-awsconfigps1" class="anchor" href="#configure-awsconfigps1" aria-hidden="true"><span class="octicon octicon-link"></span></a>Configure AWSConfig.ps1</h3>

<p>Change the AWS .NET SDK Path:</p>

<p><em>(Note the latest version has the DLLs in the \Net35 and \Net45 subdirectories of \bin - I used the \Net45 version for my 2012 R2 setup)</em></p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># AWS SDK Path </span>
<span class="pl-c1">Add-Type</span> <span class="pl-k">-</span>Path <span class="pl-s">"C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.dll"</span></pre></div>

<p>Add your AWS Access Key, Secret, and Account ID:</p>

<p><em>(Account ID can be found under your AWS username dropdown -&gt; Security Credentials -&gt; Account Identifiers.  Remove the dashes for the config file)</em></p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># Access Keys</span>
<span class="pl-k">$</span><span class="pl-smi">accessKeyID</span><span class="pl-k">=</span><span class="pl-s">"XXXXXXXXXXXXXXXXXXXX"</span>
<span class="pl-k">$</span><span class="pl-smi">secretAccessKey</span><span class="pl-k">=</span><span class="pl-s">"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"</span>
<span class="pl-k">$</span><span class="pl-smi">accountID</span> <span class="pl-k">=</span> <span class="pl-s">"############"</span></pre></div>

<p>Uncomment both the region that your instances are running in and the region for your SES emails:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># EC2 Regions</span>
<span class="pl-c"># $serviceURL="https://ec2.us-east-1.amazonaws.com" # US East (Northern Virginia)</span>
<span class="pl-c"># $serviceURL="https://ec2.us-west-2.amazonaws.com" # US West (Oregon)</span>
<span class="pl-c"># $serviceURL="https://ec2.us-west-1.amazonaws.com" # US West (Northern California)</span>
<span class="pl-c"># $serviceURL="https://ec2.eu-west-1.amazonaws.com" # EU (Ireland)</span>
<span class="pl-c"># $serviceURL="https://ec2.ap-southeast-1.amazonaws.com" # Asia Pacific (Singapore)</span>
<span class="pl-c"># $serviceURL="https://ec2.ap-southeast-2.amazonaws.com" # Asia Pacific (Sydney)</span>
<span class="pl-c"># $serviceURL="https://ec2.ap-northeast-1.amazonaws.com" # Asia Pacific (Tokyo)</span>
<span class="pl-c"># $serviceURL="https://ec2.sa-east-1.amazonaws.com" # South America (Sao Paulo)</span>

<span class="pl-c"># SES Regions</span>
<span class="pl-c"># $sesURL="https://email.us-east-1.amazonaws.com" # US East (Northern Virginia)</span>
<span class="pl-c"># $sesURL="https://email.us-west-2.amazonaws.com" # US West (Oregon)</span>
<span class="pl-c"># $sesURL="https://email.eu-west-1.amazonaws.com" # EU (Ireland)</span></pre></div>

<p>Enter your log path:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># Log</span>
<span class="pl-k">$</span><span class="pl-smi">LOG_PATH</span><span class="pl-k">=</span><span class="pl-s">"C:\AWS\Logs\"</span></pre></div>

<p>Provide a from address (must be verified in Amazon Simple Email Services (SES)) &amp; an admin address that will receive emails:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># Email</span>
<span class="pl-k">$</span><span class="pl-smi">FROM_ADDRESS</span> <span class="pl-k">=</span> <span class="pl-s">"nnn@nnn.nnn"</span>
<span class="pl-k">$</span><span class="pl-smi">ADMIN_ADDRESSES</span> <span class="pl-k">=</span> <span class="pl-s">"nnn@nnn.nnn"</span></pre></div>

<p>Edit the max number of days to keep old snapshots and the max allowable runtime of the script:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># Expiration</span>
<span class="pl-k">$</span><span class="pl-smi">EXPIRATION_DAYS</span> <span class="pl-k">=</span> <span class="pl-c1"><span class="pl-c1">7</span></span>
<span class="pl-k">$</span><span class="pl-smi">EXPIRATION_WEEKS</span> <span class="pl-k">=</span> <span class="pl-c1"><span class="pl-c1">4</span></span>
<span class="pl-k">$</span><span class="pl-smi">MAX_FUNCTION_RUNTIME</span> <span class="pl-k">=</span> <span class="pl-c1"><span class="pl-c1">60</span></span> <span class="pl-c"># minutes</span></pre></div>

<h3><a id="user-content-create-an-event-log" class="anchor" href="#create-an-event-log" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create an Event Log</h3>

<p>Execute the following line in PowerShell to allow the scripts to add entries into the event log:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c1">New-EventLog</span> <span class="pl-k">-</span>Source <span class="pl-s">"AWS PowerShell Utilities"</span> <span class="pl-k">-</span>LogName <span class="pl-s">"Application"</span></pre></div>

<h3><a id="user-content-configure-dailysnapshotsps1" class="anchor" href="#configure-dailysnapshotsps1" aria-hidden="true"><span class="octicon octicon-link"></span></a>Configure DailySnapshots.ps1</h3>

<p>Verify the paths to AWSConfig.ps1 and AWSUtilities.ps1 :</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c">############## C O N F I G ##############</span>
.<span class="pl-s">"C:\AWS\AWSConfig.ps1"</span>

<span class="pl-c">############## F U N C T I O N S ##############</span>
.<span class="pl-s">"C:\AWS\AWSUtilities.ps1"</span></pre></div>

<p>Edit the environment variables to define the Name (i.e. "Our Cloud Servers"), Type (i.e. "Staging", "Production", etc.), the Backup Type (i.e. "Daily") and, most importantly, the Tag to look for to identify instances to backup:</p>

<div class="highlight highlight-PowerShell"><pre><span class="pl-c"># Environment</span>
<span class="pl-k">$</span><span class="pl-smi">ENVIRONMENT_NAME</span> <span class="pl-k">=</span> <span class="pl-s">"Our Cloud Servers"</span>
<span class="pl-k">$</span><span class="pl-smi">ENVIRONMENT_TYPE</span> <span class="pl-k">=</span> <span class="pl-s">"Production"</span>
<span class="pl-k">$</span><span class="pl-smi">BACKUP_TYPE</span> <span class="pl-k">=</span> <span class="pl-s">"Daily"</span>
<span class="pl-k">$</span><span class="pl-smi">backupTag</span> <span class="pl-k">=</span> <span class="pl-s">"xxxxxxxx"</span> <span class="pl-c">#Make sure the value of this tag is 'Yes', without the quotes, on the instances you want backed up</span></pre></div>

<h2><a id="user-content-usage" class="anchor" href="#usage" aria-hidden="true"><span class="octicon octicon-link"></span></a>Usage</h2>

<p>Running the script DailySnapshot.ps1 will create a snapshot of each volume for each instance (without shutting them down).  Once it's complete, you'll receive an email via Amazon SES with the status of the backup and details of the process.</p>

<p>To automate the process, you can setup a recurring task in Task Scheduler.  When doing so, make sure you execute the "powershell" command and not just the script:</p>

<p><a href="https://camo.githubusercontent.com/1d2fd5c422667ae46cc947cdbb798c8b20eb4e08/687474703a2f2f692e696d6775722e636f6d2f30376f7a4b33652e706e67" target="_blank"><img src="https://camo.githubusercontent.com/1d2fd5c422667ae46cc947cdbb798c8b20eb4e08/687474703a2f2f692e696d6775722e636f6d2f30376f7a4b33652e706e67" alt="task scheduler screenshow" data-canonical-src="http://i.imgur.com/07ozK3e.png" style="max-width:100%;"></a></p>

<h2><a id="user-content-troubleshooting" class="anchor" href="#troubleshooting" aria-hidden="true"><span class="octicon octicon-link"></span></a>Troubleshooting</h2>

<p>So far a majority of the issues encountered (going purely by the small number of Github issues I've received here) have to do with IAM permissions for the user / API key executing the scripts.  Do make sure your IAM user has permissions for at least the following actions:</p>

<p>EC2:</p>

<ul>
<li>CreateTags</li>
<li>DescribeInstances</li>
<li>StartInstances</li>
<li>StopInstances</li>
<li>DescribeSnapshots</li>
<li>DeleteSnapshot</li>
<li>CreateSnapshot</li>
<li>DescribeVolumes</li>
</ul>

<p>SES:</p>

<ul>
<li>SendEmail </li>
<li>SendRawEmail</li>
</ul>

<h2><a id="user-content-contribute" class="anchor" href="#contribute" aria-hidden="true"><span class="octicon octicon-link"></span></a>Contribute</h2>

<p>I did this mostly to learn, so please excuse any bugs / awful code.  And more imporantly, please help improve these scripts!  Open an issue, fork, submit a pull request, etc.  You know the drill.  I'm game. </p>

<h2><a id="user-content-license" class="anchor" href="#license" aria-hidden="true"><span class="octicon octicon-link"></span></a>License</h2>

</article>
