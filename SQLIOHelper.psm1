$VerbosePreference = "Continue";

$scriptpath = $MyInvocation.MyCommand.Path;
$moduledirectory = Split-Path $scriptpath;

[string] $script:RootPath = New-Item -Path "C:\Russell" -Force -Type directory;
[string] $script:LogsPath = New-Item -Path (Join-Path $script:RootPath "Logs") -Force -Type directory;

function Get-DefaultWindowsImage
{
  return Get-EC2ImageByName -Names 'WINDOWS_2012R2_BASE'
  #return (Get-EC2Image -Owner amazon -Filter @{ Name="platform"; Value="windows" }, @{ Name="architecture"; Value="x86_64" }) | Where-Object Name -like "Windows_Server-2012-RTM-English-64Bit-Base-*" | Select -First 1 -ExpandProperty ImageID;
}

function ConvertTo-Base64($string) {
   $bytes = [System.Text.Encoding]::UTF8.GetBytes($string);
   $encoded = [System.Convert]::ToBase64String($bytes); 
   return $encoded;
}

function New-SQLIOInstance
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$false)][string] $AvailabilityZone,                     
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
	[Parameter(Mandatory=$false)][string] $SNSTopic = "arn:aws:sns:us-east-1:831402888584:Topic1", #Optional: Include if you would like to be notified on completion
	[Parameter(Mandatory=$false)][string] $InstanceProfile = "arn:aws:iam::831402888584:instance-profile/SQLIOResultsEC2",
    [Parameter(Mandatory=$false)][string] $UserScript = (Join-Path $script:moduledirectory "SQLIOBootstrap.ps1"),
	[Parameter(Mandatory=$false)][Bool] $Fast = $false #Only run the 4k read and write tests
  )
  Process
  {
	$Count = 1
	$ami = (Get-DefaultWindowsImage)
	$ImageID =  $ami[0].ImageId
  
 	$validVolumeTypes = 'gp2','io1';
	if ($validVolumeTypes -match $VolumeType)
	{} #valid range
	else
	{
		Write-Verbose "VolumeType parameter should be either gp2 or io1!";
		return;
	}
  
	if ($VolumeType -eq "gp2")
	{
		$IOPS = 3 * $VolumeSizeGiB;
		if ($IOPS -gt 10000){
			$IOPS = 10000; #capped @ 10K for a single volume
		}
	}
	else
	{
		#http://docs.aws.amazon.com/cli/latest/reference/ec2/create-volume.html
		#Constraint: Range is 100 to 20000 for Provisioned IOPS (SSD) volumes
		#The number of I/O operations per second (IOPS) to provision for the volume, with a maximum ratio of 30 IOPS/GiB.
		
		if ($IOPS -ge 100 -and $IOPS -le 20000)
		{} #valid range
		else
		{
			Write-Verbose "Please enter a IOPS value between 100 and 20000)";
			return;
		}
		
		#enforce: maximum ratio of 30 IOPS/GiB
		$Cap = $VolumeSizeGiB * 30;
		if($IOPS > $Cap)
		{
			$IOPS = $Cap;
		}
	}
  
	if ($VolumeSizeGiB -ge 4 -and $VolumeSizeGiB -le 16384)
	{} #valid range
	else
	{
		Write-Verbose "Please enter a volume size between 4 (4 GiB) and 16384 (16 TB)";
		return;
	}
	
	if ($TestFileSizeGB -ge 10 -and $TestFileSizeGB -le 9000)
	{} #valid range
	else	
	{
		Write-Verbose "Please enter a test file size between 10 (10 GB) and 9000 (9TB)";
		return;
	}	
  
	if ($TestFileSizeGB -ge $VolumeSizeGiB)
	{
		Write-Verbose "Test file size should be less than the volume size";
		return;
	}
  
    $Timestamp = get-date -f yyyyMMddhhmmss;
	$TestDetails = "{0}_{1}_{2}_{3}iops_{4}vlm_{5}df.txt" -f $Timestamp, $InstanceType, $VolumeType, $IOPS, $VolumeSizeGiB, $TestFileSizeGB;
	$TestDetailsNoTimeNoExt = "{0}_{1}_{2}iops_{3}vlm_{4}df" -f $InstanceType, $VolumeType, $IOPS, $VolumeSizeGiB, $TestFileSizeGB;
   
    $UserData = "";
    if ($userScript -and (Test-Path $userScript))
    {
      $contents = "<powershell>`$TestFileSizeGB=$TestFileSizeGB;`$AWSRegion=`"$Region`";`$S3ResultsBucket=`"$S3ResultsBucketName`";";
	  $contents = $contents +  "`$ResultsFileName=`"$TestDetails`";`$SNSTopic=`"$SNSTopic`";`$Fast=`"$Fast`";";
	  $contents = $contents + [System.IO.File]::ReadAllText($UserScript) + "</powershell>";
	  $filePath = gi $UserScript;
      $UserData = ConvertTo-Base64($contents);
    }
		
    $params = @{};
    $params.Add("ImageID", $ImageID);
    $params.Add("InstanceType", $InstanceType);
    $params.Add("KeyName", $KeyPairName);
    $params.Add("MaxCount", $Count);
    $params.Add("MinCount", $Count);
    if ($AvailabilityZone)
    {
      $params.Add("Placement_AvailabilityZone", $AvailabilityZone);
    }	
	
	#data volume
	$volume = New-Object Amazon.EC2.Model.EbsBlockDevice;
	$volume.VolumeSize = $VolumeSizeGiB;
	$volume.VolumeType = $VolumeType;
	if ($VolumeType -eq "io1")
	{
		$volume.IOPS = $IOPS;
	}

	#Define how the volume is going to be attached to the instance and assign the volume properties
	$DeviceMapping = New-Object Amazon.EC2.Model.BlockDeviceMapping
	$DeviceMapping.DeviceName = '/dev/sdh'
	$DeviceMapping.Ebs = $volume	
	
	$params.Add("InstanceProfile_Arn", $InstanceProfile);
    $params.Add("SecurityGroupId", $SecurityGroup);
	$params.Add("SubnetId", $SubnetId);
    $params.Add("UserData", $UserData); 
	$params.Add("BlockDeviceMapping", $DeviceMapping); 
	
	#$baseIOPS = $IOPsPerGB * $VolumeSizeGiB;
	$instanceName = "{0} - {1}" -f $TagName, $TestDetailsNoTimeNoExt;
    $reservation = New-EC2Instance @params;
	$reservation.RunningInstance |% { New-EC2Tag -ResourceId $_.InstanceID -Tag @{ Key = "Name"; Value = $instanceName } | Out-Null };
	$reservation.RunningInstance |% { New-EC2Tag -ResourceId $_.InstanceID -Tag @{ Key = "EBS IOPS"; Value = $IOPS; } | Out-Null };
    $reservation;
  }
}




