#*****************************************************************
# Script to Check the Final installation for the Crawling Modules
#
# Output: Step3_Log.txt
#
# Coveo
# Wim Nijmeijer
#*****************************************************************

function write() {
  Param ([string]$text)
  Write-Host $text
  $text | Add-Content 'Step3_log.txt'
}

"" | Set-Content 'Step3_log.txt'
$a = Get-Date -Format F

write( "" )
write( "" )
write( "======================================================" )
write( "Coveo - Crawling Modules - Final Installation Checker" )
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
$mysqlid = ""
write( "Step 1. Mysql worker running." )

try {
  $workers = docker ps -a --no-trunc  --format '{{json .}}' | ConvertFrom-Json
  foreach ( $work in $workers) {
    if ($work.Names -like "*crawlers_db*" -and $work.Status.StartsWith("Up")) {
      $valid = $true
      $mysqlid = $work.ID
    }
  }
}
catch {
}
If ($valid) {
  write( "Step 1. Valid" )
}
else {
  write( "Step 1. FAILED, MySQL (Crawlers_db) is not running." )
  $failures = $true
}
write( "=========================================" )

write( "Step 2. Checking At least one worker." )

$valid = $false

try {
  $workers = docker ps -a --format '{{json .}}' | ConvertFrom-Json
  foreach ( $work in $workers) {
    if ($work.Names -like "*worker_service*" -and $work.Status.StartsWith("Up")) {
      $valid = $true
    }
  }
}
catch {
}
if ($valid) {
  write( "Step 2. Valid" )
}
else {
  write( "Step 2. FAILED, No worker is running.")
  $failures = $true
}
write( "=========================================" )


write( "Step 3. Checking Crawling Module Service is running." )
$valid = $false
try {
  $result = Get-Service | Where-Object {$_.Name -like  "*CrawlingModules*"}
  If ($result) {
    $valid = $true
    if ($result.Status -eq "Running"){

    }
    else {
      $valid = $false
      write("Step 3. FAILED, Coveo.CrawlingModules Service is NOT started.")
    }
  } 
}
catch {
}
If ($valid) {
  write( "Step 3. Valid" )
}
else {
  write( "Step 3. FAILED, Coveo.CrawlingModules Service is not there or not started, re-install." )
  $failures = $true
}
write( "=========================================" )


write( "Step 4. Checking Docker Service is running." )
$valid = $false
try {
  $result = Get-Service | Where-Object {$_.Name -like  "*Docker*"}
  If ($result) {
    $valid = $true
    if ($result.Status -eq "Running"){

    }
    else {
      $valid = $false
      write("Step 4. FAILED, Docker Service is NOT started.")
    }
  } 
}
catch {
}
If ($valid) {
  write( "Step 4. Valid" )
}
else {
  write( "Step 4. FAILED, Docker Service is not there or is not started, re-install." )
  $failures = $true
}
write( "=========================================" )


write( "Step 5. Checking Event Log for problems with MySql." )
$valid = $true
try {
  $result = Get-EventLog -Log "Application" -Source "docker" -EntryType "Error"  -After (Get-Date).AddHours(-24) | Where-Object {$_.Message -like  "*$mysqlid*"}
  If ($result) {
    $valid = $false
  } 
}
catch {
}
If ($valid) {
  write( "Step 5. Valid" )
}
else {
  write( "Step 5. FAILED, MySql has problems, re-install." )
  $failures = $true
}
write( "=========================================" )


write( "Step 6. Checking Docker Log for problems with MySql." )
$valid = $true
try {
  $result = docker logs --since=24h $mysqlid
  If ($result) {
    foreach ( $work in $result) {
      if ($work -like "*cannot be started*" ) {
        $valid = $false
      }
    }
   
  } 
}
catch {
}
If ($valid) {
  write( "Step 6. Valid" )
}
else {
  write( "Step 6. FAILED, MySql has problems, re-install." )
  $failures = $true
}
write( "=========================================" )


if ($failures) {
  write( "" )
  write( "=========================================================================" )
  write( "! You have failures, fix them first before adding content. !" )
  write( "=========================================================================" )
  write( "" )

}
else {
  write( "" )
  write( "You have no failures, proceed with adding content!." )
  write( "See: https://docs.coveo.com/en/170/cloud-v2-developers/creating-a-crawling-module-source" )
  write( "" )

}