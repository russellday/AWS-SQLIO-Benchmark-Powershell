$VerbosePreference = "Continue";
$scriptpath = $MyInvocation.MyCommand.Path;
$moduledirectory = Split-Path $scriptpath;

function Invoke-Wrapper
{
	Initialize-AWSPowershell
	Install-SQLIO
  	FSUTIL.EXE File CreateNew D:\TestFile.DAT ($TestFileSizeGB*1GB)
	FSUTIL.EXE File SetValidData D:\TestFile.DAT ($TestFileSizeGB*1GB)
	Invoke-SQLIO
	Publish-ResultsToS3
	Publish-SNSNotification
	Terminate-EC2Instance
}

function Initialize-AWSPowershell
(
    [switch] $Force
)
{
  if (-not (Test-Path "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1") -or $Force)
  {
     $dest = Join-Path $env:TEMP "AWSToolsAndSDKForNet.msi";
     Write-Host "Downloading installer package for Amazon AWSPowershell";
     Invoke-WebRequest -Uri "http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi" -OutFile $dest;
	   Write-Host "Installing Amazon AWSPowershell";
	   Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $dest /qn" -Wait -Passthru;
	   Remove-Item $dest;    
	}
}

function Install-SQLIO
{
    if (Test-Path "C:\Program Files (X86)\SQLIO\") {
        Write-Verbose "SQLIO are already installed";
        return;
    }
	
    $dest = Join-Path $env:TEMP "SQLIO.msi";
    Write-Host "Downloading installer package for SQLIO";
	Invoke-WebRequest -Uri "http://download.microsoft.com/download/f/3/f/f3f92f8b-b24e-4c2e-9e86-d66df1f6f83b/SQLIO.msi" -OutFile $dest;
	Write-Host "Installing SQLIO";
	Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $dest /qn" -Wait -Passthru;
	Remove-Item $dest;   

	$destinationFolder = "D:\SQLIO";
	if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
	Copy-Item "C:\Program Files (X86)\SQLIO\sqlio.exe" -Destination $destinationFolder
	 
}

function Invoke-SQLIO
{

	if ([Bool]::Parse($Fast)) 
	{
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -frandom -b4 -BH -LS d:\TestFile.DAT > d:\results.txt	
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -frandom -b4 -BH -LS d:\TestFile.DAT >> d:\results.txt
	}
	else
	{
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -frandom -b4 -BH -LS d:\TestFile.DAT > d:\results.txt	
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -frandom -b8 -BH -LS d:\TestFile.DAT >> d:\results.txt	
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -frandom -b32 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -frandom -b64 -BH -LS d:\TestFile.DAT >> d:\results.txt

		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -frandom -b4 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -frandom -b8 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -frandom -b32 -BH -LS d:\TestFile.DAT >> d:\results.txt 
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -frandom -b64 -BH -LS d:\TestFile.DAT >> d:\results.txt

		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -fsequential -b4 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -fsequential -b8 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -fsequential -b32 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kW -t8 -s360 -o8 -fsequential -b64 -BH -LS d:\TestFile.DAT >> d:\results.txt

		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -fsequential -b4 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -fsequential -b8 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -fsequential -b32 -BH -LS d:\TestFile.DAT >> d:\results.txt
		d:\sqlio\sqlio.exe -kR -t8 -s360 -o8 -fsequential -b64 -BH -LS d:\TestFile.DAT >> d:\results.txt
	}
}

function Publish-ResultsToS3
{
	Write-S3Object -BucketName $S3ResultsBucket -File d:\results.txt -Key $ResultsFileName
}

function Publish-SNSNotification
{
	if ($SNSTopic -ne "")
	{
		Publish-SNSMessage -TopicArn $SNSTopic -Subject "SQLIO Benchmark Complete" -Message "Results: $ResultsFileName" -Region $AWSRegion;
	}	
}

function Terminate-EC2Instance
{
	$instanceID = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id");
	Stop-EC2Instance -Instance $instanceID -Terminate -Region $AWSRegion;
}

#Call Functions to run on EC2 instance...	
Invoke-Wrapper | Out-File "c:\Log.txt" -Verbose;




