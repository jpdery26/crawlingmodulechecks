#*****************************************************************
# Script to Check the Docker installation for the Crawling Modules
#
# Output: Step2_Log.txt
#
# Coveo
# Wim Nijmeijer
#*****************************************************************

function write() {
  Param ([string]$text)
  Write-Host $text
  $text | Add-Content 'Step2_log.txt'
}

"" | Set-Content 'Step2_log.txt'
$a = Get-Date -Format F

write( "" )
write( "" )
write( "======================================================" )
write( "Coveo - Crawling Modules - Docker Installation Checker" )
write( "  V1.2" )
write( "======================================================" )
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
$valid = $false 
write( "Step 1. Checking Docker version." )

try {
  $version = docker version --format '{{json .}}' | ConvertFrom-Json
  If ($version.Client.version = $version.Server.version) {
    $valid = $true
  }
}
catch {
}
If ($valid) {
  write( "Step 1. Valid" )
}
else {
  write( "Step 1. FAILED, Docker Client and Server have different versions." )
  $failures = $true
}
write( "=========================================" )

write( "Step 2. Checking Docker Windows Mode." )

$valid = $false
if ($version) {
  If ($version.Client.Arch = $version.Server.Arch -and $version.Client.Arch -eq "amd64" -and $version.Client.Os -eq "windows") {
    $valid = $true
  }
}
if ($valid) {
  write( "Step 2. Valid" )
}
else {
  write( "Client Arch: $($version.Client.Arch)")
  write( "Client Os  : $($version.Client.Os)")
  write( "Step 2. FAILED, Docker Client & Server are not properly configured. Arch should be amd64 and Client should be windows.")
  $failures = $true
}
write( "=========================================" )


write( "Step 3. Checking if docker can run." )
$valid = $false
try {
  $result = docker run hello-world
  If ($result -like "*Hello from Docker*") {
    $valid = $true
  } 
}
catch {
}
If ($valid) {
  write( "Step 3. Valid" )
}
else {
  write( "Step 3. FAILED, Docker does not run properly, re-install." )
  $failures = $true
}
write( "=========================================" )



write( "Step 4. Checking if swarm can be created." )
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
# $ipV4.IPAddressToString
write( "On IP: $($ipV4.IPAddressToString)" )
$valid = $false
try {
  $result = docker swarm init --advertise-addr $ipV4.IPAddressToString

  If ($result -contains "Swarm initialized.") {
    $valid = $true  
  }  
}
catch {
}

If ($valid) {
  write( "Step 4. Valid" )
  docker swarm leave --force
}
else {
  write( "Step 4. FAILED, Docker does not run properly, Swarm could not be created. Re-install." )
  $failures = $true
}
write( "=========================================" )

if ($failures) {
  write( "" )
  write( "=========================================================================" )
  write( "! You have failures, fix them first before starting the docker workers. !" )
  write( "=========================================================================" )
  write( "" )

}
else {
  write( "You have no failures, proceed with the installation of Maestro." )
  write( "See: https://docs.coveo.com/en/71/cloud-v2-developers/installing-maestro" )
  write( "" )

}