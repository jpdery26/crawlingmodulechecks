#***********************************************************
# Script to Check the Prerequisites for the Crawling Modules
#
# Output: Step1_Log.txt
#
# Coveo
# Wim Nijmeijer
#***********************************************************

function checkURL() {
  Param ([string]$url)
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  [System.Net.ServicePointManager]::DefaultConnectionLimit = 1024
  $request = [System.Net.WebRequest]::Create($url)
  $request.method = "head"
  if ($proxy) {
    $myproxy = $proxy
    if ($url -like 'https') {
      $myproxy = $proxys
    }
    $WebProxy = New-Object System.Net.WebProxy($myproxy, $true)
    $request.Proxy = $WebProxy
  } 
  $request.Timeout = 6000
  try {
    $response = $request.GetResponse()
    $code = [int]$response.StatusCode
  }
  catch {
    $code = 300
    $ErrorMessage = $_.Exception.Message
    #writeln( $ErrorMessage
    if ($ErrorMessage -like "*403*") {
      $code = 200
    }
    if ($ErrorMessage -like "*405*") {
      $code = 200
    }
  }
  return $code
}


function writeln () {
  Param ([string]$text,
  [Parameter(Mandatory=$false)][System.ConsoleColor]$color)
  if ($color -eq $null){
    Write-Host $text
  }
  else {
    Write-Host $text -ForegroundColor $color
  }
  Add-Content "Step1_log.txt" "$text"
}

"" | Set-Content 'Step1_log.txt'
$a = Get-Date -Format F

writeln ""
writeln ""
writeln "================================================="
writeln "Coveo - Crawling Modules - Pre Requisites Checker"
writeln "  V1.4"
writeln "================================================="
writeln ""
writeln "Created on  : $a"
writeln ""
writeln "Machine data:"
$cs = Get-WmiObject -class Win32_ComputerSystem
$Cores = $cs.numberoflogicalprocessors
$Mem = [math]::Ceiling($cs.TotalPhysicalMemory / 1024 / 1024 / 1024)
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
#Check Proxy
$proxy = [Environment]::GetEnvironmentVariable("HTTP_PROXY", [EnvironmentVariableTarget]::Machine)
$proxys = [Environment]::GetEnvironmentVariable("HTTPS_PROXY", [EnvironmentVariableTarget]::Machine)
writeln "  Name       : $($cs.Name)"
writeln "  No of Cores: $Cores"
writeln "  RAM        : $Mem Gb"
writeln "  Domain     : $($cs.Domain)"
writeln "  IPv4       : $($ipV4.IPAddressToString)"
if ($proxy) {
  writeln "  Proxy HTTP : $proxy"
}
if ($proxys) {
  writeln "  Proxy HTTPS: $proxys"
}
writeln ""
writeln "================================================="
$failures = $false 
writeln "Step 1. Checking access to internet (https://www.coveo.com)."
#Check if we can access api.cloud.coveo.com
$code = checkURL("https://www.coveo.com")
#$response = Test-Connection -Cn api.cloud.coveo.com -BufferSize 16 -Count 1 -ea 0 -quiet

If ($code -eq 200) {
  writeln "Step 1. Valid" Green
}
else {
  writeln "Step 1. FAILED, Check your firewall settings or define a proxy." Red
  $failures = $true
}
writeln "========================================="



writeln "Step 2. Checking access to https://platform.cloud.coveo.com"
#Check if we can access platform cloud.coveo.com
$code = checkURL("https://platform.cloud.coveo.com/admin")

If ($code -eq 200) {
  writeln "Step 2. Valid" Green
}
else {
  writeln "Step 2. FAILED, Check your firewall settings or define a proxy." Red
  $failures = $true
}
writeln "========================================="

writeln "Step 3. Checking access to https://api.cloud.coveo.com"
#Check if we can access api.cloud.coveo.com
#$response = Test-Connection -Cn api.cloud.coveo.com -BufferSize 16 -Count 1 -ea 0 -quiet
$code = checkURL("https://api.cloud.coveo.com")
If ($code -eq 200) {
  writeln "Step 3. Valid" Green
}
else {
  writeln "Step 3. FAILED, Check your firewall settings or define a proxy." Red
  $failures = $true
}
writeln "========================================="

writeln "Step 4. Checking Free Space in C:"
$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = 'C:'" 
$free = $disk.FreeSpace / 1GB
$freetext = [math]::Round($free, 2)
If ($free -gt 200) {
  writeln "Step 4. Valid, $freetext Gb space available." Green
}
else {
  writeln "Step 4. FAILED ($freetext Gb Free ), You need to have at least 200 Gb space available on C:." Red
  $failures = $true
}
writeln "========================================="

writeln "Step 5. Checking Registry access"

$reg = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'
 
If ($reg) {
  writeln "Step 5. Valid." Green
}
else {
  writeln "Step 5. FAILED, Make sure your antivirus is not blocking Registry Access." Red
  $failures = $true
}
writeln "========================================="


writeln "Step 6. Checking S3 Access, https://s3.amazonaws.com "
$code = checkURL("https://s3.amazonaws.com")
#$response = Test-Connection -Cn s3.amazonaws.com -BufferSize 16 -Count 1 -ea 0 -quiet
if ($code -eq 200) {
  writeln "Step 6. Valid" Green
}
else {
  writeln "Step 6. FAILED, Check your firewall settings or define a proxy." Red
  $failures = $true
}
writeln "========================================="


writeln "Step 7. Hardware check "

if ($Cores -ge 4 -and $Mem -ge 16) {
  writeln "Step 7. Valid" Green
}
else {
  writeln "Step 7. FAILED, You must have minimal 4 CPU's and 16 Gb of RAM." Red
  $failures = $true
}



  $buildNumber = (Get-CimInstance -Namespace root\cimv2 Win32_OperatingSystem).BuildNumber
  
  writeln "========================================="


  writeln "Step 8. OS: Is Windows 10 Anniversary Update or Windows Server 2016 "
  
  if ($buildNumber -ge 14393) {
    writeln "Step 8. Valid" Green
  }
  else {
    writeln "Step 8. FAILED, Install the proper OS." Red
    $failures = $true
  }

  writeln "========================================="


  writeln "Step 9. OS: Has KB3192366, KB3194496, or later installed if running Windows build 14393 "
  
  if ($buildNumber -eq 14393 -and  (Get-ItemProperty -Path 'HKLM:\software\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR -gt 351) {
    writeln "Step 9. Valid" Green
  }
  else {
    if ($buildNumber -eq 14393){
    writeln "Step 9. FAILED, Install the proper OS." Red
    $failures = $true
    }
    else {
      writeln "Step 9. Valid" Green
    }
  }

  writeln "========================================="


  writeln "Step 10. OS: Is not a build with blocking issues "
  
  if ($buildNumber -ne 14391 -and $buildNumber -ne 14936) {
    writeln "Step 10. Valid" Green
  }
  else {
    writeln "Step 10. FAILED, Install the proper OS." Red
    $failures = $true
  }
  

  writeln "========================================="


  writeln "Step 11 OS: Has 'Containers' feature installed "
  $valid = $false
  if (((Get-ComputerInfo).WindowsInstallationType) -eq "Client") {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Containers).State -eq  "Enabled"){
      $valid = $true
    }
}
else {
    if ((Get-WindowsFeature -Name Containers).InstallState -eq "Installed")
    {
      $valid = $true
    }
}

  if ($valid) {
    writeln "Step 11. Valid" Green
  }
  else {
    writeln "Step 11. FAILED, Install the 'containers' Feature." Red
    $failures = $true
  }
  
writeln "Step 12. Removing all C:\Windows\Temp\hcs* folders "
Remove-Item "c:\windows\temp\hcs*" -Force -Recurse -ErrorAction SilentlyContinue 
writeln "Step 12. Done" Green

if ($failures) {
  writeln ""
  writeln "========================================================================="
  writeln "! You have failures, fix them first before proceeding the installation. !" Red
  writeln "========================================================================="
  writeln ""

}
else {
  writeln ""
  writeln "You have no failures, proceed with the installation." Green
  writeln "See: https://docs.coveo.com/en/96/cloud-v2-developers/installing-docker#installing-docker-enterprise-edition"
  writeln ""

}