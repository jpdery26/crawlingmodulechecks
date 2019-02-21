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
    #write( $ErrorMessage
    if ($ErrorMessage -like "*403*") {
      $code = 200
    }
    if ($ErrorMessage -like "*405*") {
      $code = 200
    }
  }
  return $code
}

function write() {
  Param ([string]$text)
  Write-Host $text
  $text | Add-Content 'Step1_log.txt'
}

"" | Set-Content 'Step1_log.txt'
$a = Get-Date -Format F

write( "" )
write( "" )
write( "=================================================" )
write( "Coveo - Crawling Modules - Pre Requisites Checker" )
write( "  V1.2" )
write( "=================================================" )
write( "" )
write( "Created on  : $a" )
write( "" )
write( "Machine data:" )
$cs = Get-WmiObject -class Win32_ComputerSystem
$Cores = $cs.numberoflogicalprocessors
$Mem = [math]::Ceiling($cs.TotalPhysicalMemory / 1024 / 1024 / 1024)
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
#Check Proxy
$proxy = [Environment]::GetEnvironmentVariable("HTTP_PROXY", [EnvironmentVariableTarget]::Machine)
$proxys = [Environment]::GetEnvironmentVariable("HTTPS_PROXY", [EnvironmentVariableTarget]::Machine)
write( "  Name       : $($cs.Name)" )
write( "  No of Cores: $Cores" )
write( "  RAM        : $Mem Gb" )
write( "  Domain     : $($cs.Domain)")
write( "  IPv4       : $($ipV4.IPAddressToString)")
if ($proxy) {
  write( "  Proxy HTTP : $proxy" )
}
if ($proxys) {
  write( "  Proxy HTTPS: $proxys" )
}
write( "" )
write( "=================================================" )
$failures = $false 
write( "Step 1. Checking access to internet (https://www.coveo.com)." )
#Check if we can access api.cloud.coveo.com
$code = checkURL("https://www.coveo.com")
#$response = Test-Connection -Cn api.cloud.coveo.com -BufferSize 16 -Count 1 -ea 0 -quiet

If ($code -eq 200) {
  write( "Step 1. Valid" )
}
else {
  write( "Step 1. FAILED, Check your firewall settings or define a proxy." )
  $failures = $true
}
write( "=========================================" )



write( "Step 2. Checking access to https://platform.cloud.coveo.com" )
#Check if we can access platform cloud.coveo.com
$code = checkURL("https://platform.cloud.coveo.com/admin")

If ($code -eq 200) {
  write( "Step 2. Valid" )
}
else {
  write( "Step 2. FAILED, Check your firewall settings or define a proxy." )
  $failures = $true
}
write( "=========================================" )

write( "Step 3. Checking access to https://api.cloud.coveo.com" )
#Check if we can access api.cloud.coveo.com
#$response = Test-Connection -Cn api.cloud.coveo.com -BufferSize 16 -Count 1 -ea 0 -quiet
$code = checkURL("https://api.cloud.coveo.com")
If ($code -eq 200) {
  write( "Step 3. Valid" )
}
else {
  write( "Step 3. FAILED, Check your firewall settings or define a proxy." )
  $failures = $true
}
write( "=========================================" )

write( "Step 4. Checking Free Space in C:" )
$disk = Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = 'C:'" 
$free = $disk.FreeSpace / 1GB
$freetext = [math]::Round($free, 2)
If ($free -gt 200) {
  write( "Step 4. Valid, $freetext Gb space available." )
}
else {
  write( "Step 4. FAILED ($freetext Gb Free ), You need to have at least 200 Gb space available on C:." )
  $failures = $true
}
write( "=========================================" )

write( "Step 5. Checking Registry access" )

$reg = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\'
 
If ($reg) {
  write( "Step 5. Valid." )
}
else {
  write( "Step 5. FAILED, Make sure your antivirus is not blocking Registry Access." )
  $failures = $true
}
write( "=========================================" )


write( "Step 6. Checking S3 Access, https://s3.amazonaws.com " )
$code = checkURL("https://s3.amazonaws.com")
#$response = Test-Connection -Cn s3.amazonaws.com -BufferSize 16 -Count 1 -ea 0 -quiet
if ($code -eq 200) {
  write( "Step 6. Valid" )
}
else {
  write( "Step 6. FAILED, Check your firewall settings or define a proxy." )
  $failures = $true
}
write( "=========================================" )


write( "Step 7. Hardware check " )

if ($Cores -ge 4 -and $Mem -ge 16) {
  write( "Step 7. Valid" )
}
else {
  write( "Step 7. FAILED, You must have minimal 4 CPU's and 16 Gb of RAM." )
  $failures = $true
}

if ($failures) {
  write( "" )
  write( "=========================================================================" )
  write( "! You have failures, fix them first before proceeding the installation. !" )
  write( "=========================================================================" )
  write( "" )

}
else {
  write( "You have no failures, proceed with the installation." )
  write( "See: https://docs.coveo.com/en/96/cloud-v2-developers/installing-docker#installing-docker-enterprise-edition" )
  write( "" )

}