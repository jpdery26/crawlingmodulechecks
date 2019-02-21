#*****************************************************************
# Script to Check the Docker installation for the Crawling Modules
#
# Output: Step2_Log.txt
#
# Coveo
# Wim Nijmeijer
#*****************************************************************

function writeln() {
  Param ([string]$text)
  Write-Host $text
  Add-Content 'Step2_log.txt' "$text"
}

"" | Set-Content 'Step2_log.txt'
$a = Get-Date -Format F

writeln( "" )
writeln( "" )
writeln( "======================================================" )
writeln( "Coveo - Crawling Modules - Docker Installation Checker" )
writeln( "  V1.2" )
writeln( "======================================================" )
writeln( "" )
writeln( "Created on  : $a" )
writeln( "" )
writeln( "Machine data:" )
$cs = Get-WmiObject -class Win32_ComputerSystem
$Cores = $cs.numberoflogicalprocessors
$Mem = [math]::Ceiling($cs.TotalPhysicalMemory / 1024 / 1024 / 1024)
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
#Check Proxy
$proxy = [Environment]::GetEnvironmentVariable("HTTP_PROXY", [EnvironmentVariableTarget]::Machine)
$proxys = [Environment]::GetEnvironmentVariable("HTTPS_PROXY", [EnvironmentVariableTarget]::Machine)
writeln( "  Name       : $($cs.Name)" )
writeln( "  No of Cores: $Cores" )
writeln( "  RAM        : $Mem Gb" )
writeln( "  Domain     : $($cs.Domain)")
writeln( "  IPv4       : $($ipV4.IPAddressToString)")
if ($proxy) {
  writeln( "  Proxy HTTP : $proxy" )
}
if ($proxys) {
  writeln( "  Proxy HTTPS: $proxys" )
}
writeln( "" )
writeln( "=================================================" )
$failures = $false
$valid = $false 
writeln( "Step 1. Checking Docker version." )

try {
  $version = docker version --format '{{json .}}' | ConvertFrom-Json
  If ($version.Client.version = $version.Server.version) {
    $valid = $true
  }
}
catch {
}
If ($valid) {
  writeln( "Step 1. Valid" )
}
else {
  writeln( "Step 1. FAILED, Docker Client and Server have different versions." )
  $failures = $true
}
writeln( "=========================================" )

writeln( "Step 2. Checking Docker Windows Mode." )

$valid = $false
if ($version) {
  If ($version.Client.Arch = $version.Server.Arch -and $version.Client.Arch -eq "amd64" -and $version.Client.Os -eq "windows") {
    $valid = $true
  }
}
if ($valid) {
  writeln( "Step 2. Valid" )
}
else {
  writeln( "Client Arch: $($version.Client.Arch)")
  writeln( "Client Os  : $($version.Client.Os)")
  writeln( "Step 2. FAILED, Docker Client & Server are not properly configured. Arch should be amd64 and Client should be windows.")
  $failures = $true
}
writeln( "=========================================" )


writeln( "Step 3. Checking if docker can run." )
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
  writeln( "Step 3. Valid" )
}
else {
  writeln( "Step 3. FAILED, Docker does not run properly, re-install." )
  $failures = $true
}
writeln( "=========================================" )



writeln( "Step 4. Checking if swarm can be created." )
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
# $ipV4.IPAddressToString
writeln( "On IP: $($ipV4.IPAddressToString)" )
$valid = $false
try {
  $result = docker swarm init --advertise-addr $ipV4.IPAddressToString

  If ($result -like "*Swarm initialized:*") {
    $valid = $true  
  }  
  else {
    writeln("Step 4. Error: $result")
  }
}
catch {
}

If ($valid) {
  writeln( "Step 4. Valid" )
  $result = docker swarm leave --force
}
else {
  writeln( "Step 4. FAILED, Docker does not run properly, Swarm could not be created. Re-install." )
  $failures = $true
}
writeln( "=========================================" )

if ($failures) {
  writeln( "" )
  writeln( "=========================================================================" )
  writeln( "! You have failures, fix them first before installing Maestro. !" )
  writeln( "=========================================================================" )
  writeln( "" )

}
else {
  writeln( "" )
  writeln( "You have no failures, proceed with the installation of Maestro." )
  writeln( "See: https://docs.coveo.com/en/71/cloud-v2-developers/installing-maestro" )
  writeln( "" )

}