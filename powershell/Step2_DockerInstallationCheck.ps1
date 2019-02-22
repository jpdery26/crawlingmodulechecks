#*****************************************************************
# Script to Check the Docker installation for the Crawling Modules
#
# Output: Step2_Log.txt
#
# Coveo
# Wim Nijmeijer
#*****************************************************************

function writeln () {
  Param ([string]$text,
  [Parameter(Mandatory=$false)][System.ConsoleColor]$color)
  if ($color -eq $null){
    Write-Host $text
  }
  else {
    Write-Host $text -ForegroundColor $color
  }
  Add-Content 'Step2_log.txt' "$text"
}

"" | Set-Content 'Step2_log.txt'
$a = Get-Date -Format F

writeln  ""
writeln  ""
writeln  "======================================================"
writeln  "Coveo - Crawling Modules - Docker Installation Checker"
writeln  "  V1.4"
writeln  "======================================================"
writeln  ""
writeln  "Created on  : $a"
writeln  ""
writeln  "Machine data:"
$cs = Get-WmiObject -class Win32_ComputerSystem
$Cores = $cs.numberoflogicalprocessors
$Mem = [math]::Ceiling($cs.TotalPhysicalMemory / 1024 / 1024 / 1024)
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
#Check Proxy
$proxy = [Environment]::GetEnvironmentVariable("HTTP_PROXY", [EnvironmentVariableTarget]::Machine)
$proxys = [Environment]::GetEnvironmentVariable("HTTPS_PROXY", [EnvironmentVariableTarget]::Machine)
writeln  "  Name       : $($cs.Name)"
writeln  "  No of Cores: $Cores"
writeln  "  RAM        : $Mem Gb"
writeln  "  Domain     : $($cs.Domain)"
writeln  "  IPv4       : $($ipV4.IPAddressToString)"
if ($proxy) {
  writeln  "  Proxy HTTP : $proxy"
}
if ($proxys) {
  writeln  "  Proxy HTTPS: $proxys"
}
writeln  ""
writeln  "================================================="
$failures = $false
$valid = $false 
writeln  "Step 1. Checking Docker version."

try {
  $version = docker version --format '{{json .}}' | ConvertFrom-Json
 
  If ($version.Client.version = $version.Server.version) {
    $valid = $true
  }
}
catch {
}
If ($valid) {
  writeln  "Step 1. Valid" Green
}
else {
  writeln  "Step 1. FAILED, Docker Client and Server have different versions." Red
  $failures = $true
}
writeln  "========================================="

writeln  "Step 2. Checking Docker Windows Mode."

$valid = $false
if ($version) {
  If ($version.Client.Arch = $version.Server.Arch -and $version.Client.Arch -eq "amd64" -and $version.Client.Os -eq "windows") {
    $valid = $true
  }
}
if ($valid) {
  writeln  "Step 2. Valid" Green
}
else {
  writeln  "Client Arch: $($version.Client.Arch)"
  writeln  "Client Os  : $($version.Client.Os)"
  writeln  "Step 2. FAILED, Docker Client & Server are not properly configured. Arch should be amd64 and Client should be windows." Red
  $failures = $true
}
writeln  "========================================="


writeln  "Step 3. Checking if docker can run."
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
  writeln  "Step 3. Valid" Green
}
else {
  writeln  "Step 3. FAILED, Docker does not run properly, re-install." Red
  $failures = $true
}
writeln  "========================================="



writeln  "Step 4. Checking if swarm can be created."
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
# $ipV4.IPAddressToString
writeln  "On IP: $($ipV4.IPAddressToString)"
$valid = $false
try {
  $result = docker swarm init --advertise-addr $ipV4.IPAddressToString

  If ($result -like "*Swarm initialized:*") {
    $valid = $true  
  }  
  else {
    #writeln "Step 4. Error: $result" 
  }
}
catch {
}

If ($valid) {
  writeln  "Step 4. Valid" Green
  $result = docker swarm leave --force
}
else {
  writeln  "Step 4. FAILED, Docker does not run properly, Swarm could not be created. Re-install." Red
  $failures = $true
}
writeln  "========================================="


writeln  "Docker Info written to DockerInfo_log.txt. "
#Adding docker info
Start-Process -NoNewWindow `
                        -Wait `
                        -FilePath docker.exe `
                        -ArgumentList "info" `
                        -RedirectStandardError Errors.txt `
                        -RedirectStandardOutput DockerInfo_log.txt
writeln  "Docker Info written to DockerVersion_log.txt. "
                        Start-Process -NoNewWindow `
                        -Wait `
                        -FilePath docker.exe `
                        -ArgumentList "version" `
                        -RedirectStandardError Errors.txt `
                        -RedirectStandardOutput DockerVersion_log.txt
writeln  "Docker Network Info written to DockerNetwork_log.txt. "
                        Start-Process -NoNewWindow `
                        -Wait `
                        -FilePath docker.exe `
                        -ArgumentList "network ls" `
                        -RedirectStandardError Errors.txt `
                        -RedirectStandardOutput DockerNetwork_log.txt

$networksListOutput = Get-Content .\DockerNetwork_log.txt

$networks = $networksListOutput | Foreach-object {
    if (($_ -match "^NETWORK") -eq $false) {
        $trimmed = [regex]::Replace($_, "\s{2,}", " ")
        $split = $trimmed.Split(" ")
        New-Object -Typename PSObject -Property @{Driver=$split[2];
        NetName=$split[1];
        Scope=$split[3]}
    }
}
                     
  # Get all NAT networks
  $natNetworks = $networks | Where-Object { ($_.Driver -eq "nat")}

  # Get all Transparent networks
  $transparentNetworks = $networks | Where-Object { ($_.Driver -eq "transparent")}

  # Get all l2bridge networks
  $l2bridgeNetworks = $networks | Where-Object { ($_.Driver -eq "l2bridge")}

  $hostips = @()
  if ($natNetworks -ne $null)
  {
      # Get VMSwitch for NAT network
      if ($natNetworks[0].NetName -eq "nat")
      {
        $natVMSwitchName = "nat"
      }
      else
      {
        $natVMSwitchName = docker.exe network inspect --format="{{.Id}}" $natNetworks[0].NetName
      }

      $natGatewayIP = docker.exe network inspect --format="{{range .IPAM.Config }}{{.Gateway}}{{end}}" $natNetworks[0].NetName

      #$switchType = (Get-VMSwitch -SwitchName $natNetworks[0].NetName).SwitchType
      $switchType = (Get-VMSwitch -SwitchName $natVMSwitchName).SwitchType

      # TODO - Add checks for the case where there are no (default) nat networks, everything will need to be user-defined
      $natInternalPrefix = docker.exe network inspect --format="{{range .IPAM.Config }}{{.Subnet}}{{end}}" $natNetworks[0].NetName
      if ($natInternalPrefix.Contains("/"))
      {
        $Temp = $natInternalPrefix.Split("/")
        $Prefix = $Temp[0]
        $Length = $Temp[1]
      }
      $IPSubnet = [Net.IPAddress]::Parse($Prefix)
      $BinaryIPSubnet = [String]::Join('', $( $IPSubnet.GetAddressBytes() | %{
              [Convert]::ToString($_, 2).PadLeft(8, '0') } ))

      # Get all Host IP Addresses from Container Host
      $hostips = Get-NetIPAddress -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch "Loopback"  -And $_.InterfaceAlias -notmatch "HNS" -And $_.InterfaceAlias -notmatch "NAT" } | Select IPAddress
  }

  writeln  "========================================="

  writeln  "Step 5. One local container network is available."

  $localNetworks = $networks | Where-Object { ($_.Scope -eq "local")}
  $nr = ($localNetworks | Measure-Object).Count
  if ($nr -gt 0){
    writeln  "Step 5. Valid" Green
  } else {
    writeln  "Step 5. FAILED, Check your network configuration." Red
    $failures = $true
  }


  # Either need NAT, L2bridge, or Transparent for for external network access.
      $totalnets = 0
      if ($natNetworks -ne $null)
      {
        $totalnets += ($natNetworks | Measure-Object).Count
      }

      if ($transparentNetworks -ne $null)
      {
        $totalnets += ($transparentNetworks | Measure-Object).Count
      }

      if ($l2bridgeNetworks -ne $null)
      {
        $totalnets += ($l2bridgeNetworks | Measure-Object).Count
      }

   

  writeln  "========================================="

  writeln  "Step 6. At least one NAT, Transparent, or L2Bridge Network exists."

  if ($totalnets -gt 0){
    writeln  "Step 6. Valid" Green
  } else {
    writeln  "Step 6. FAILED, Check your network configuration." Red
    $failures = $true
  }

  writeln  "========================================="
  $winnatCount = (Get-NetNat | Measure-Object).Count
  if ($winnatCount -eq 0){
    writeln "Step 7. Skipping: NAT Network's vSwitch is internal."
    writeln  "Step 8. Skipping: A Windows NAT is configured if a Docker NAT network exists."
  } else {
    
  
  writeln  "Step 7. NAT Network's vSwitch is internal."

  if ($switchType -eq "Internal"){
    writeln  "Step 7. Valid" Green
  } else {
    writeln  "Step 7. FAILED, Check your network configuration." Red
    $failures = $true
  }


      $winnatCount = (Get-NetNat | Measure-Object).Count
      $natCount = 0
      if ($natNetworks -ne $null)
      {
          $natCount += ($natNetworks | Measure-Object).Count
      }
    

  writeln  "========================================="

  writeln  "Step 8. A Windows NAT is configured if a Docker NAT network exists."

  if ($winnatCount -ge $natCount){
    writeln  "Step 8. Valid" Green
  } else {
    writeln  "Step 8. FAILED, Check your network configuration." Red
    $failures = $true
  }

  }
     $vmnicIps = Get-NetIPAddress -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch "Loopback"  -And $_.InterfaceAlias -match "vEthernet" } | Select IPAddress

      $vmNicGatewayIPExists = $false
      $vmnicIps | Foreach-object {
        if ($_ -match $natGatewayIP) {
            $vmNicGatewayIPExists = $true
        }
      }
     

  
  writeln  "========================================="
  $valid=$true
  writeln  "Step 9. Specified Network Gateway IP for NAT network is assigned to Host vNIC."
  if ([string]::IsNullOrEmpty($natGatewayIP))
  {
      $valid=$false
      writeln  "Step 9. NAT Gateway IP is empty." Red
  }
  if ($vmNicGatewayIPExists -eq $false)
  {
     $valid = $false
  }
  if ($valid){
    writeln  "Step 9. Valid" Green
  } else {
    writeln  "Step 9. FAILED, Check your network configuration." Red
    $failures = $true
  }

  writeln  "========================================="
  $valid=$true
  writeln  "Step 10. NAT Network's internal prefix does not overlap with external IP."
  $hostips
  if ( ($hostips | measure-object).Count -gt 0)
      {
        $hostips | Foreach-object {
            $testip = [Net.IPAddress]::Parse( ($_.IPAddress) )
            $BinaryIP = [String]::Join('', $( $testip.GetAddressBytes() | %{
                [Convert]::ToString($_, 2).PadLeft(8, '0') } ))

            if ($BinaryIP.Substring(0, $Length) -eq $BinaryIPSubnet.Substring(0, $Length))
            {
              $valid=$false
              writeln "BinaryIP equal to BinaryIPSubnet, should not be."
            }
             
        }
      }
      else
      {
        if ($hostips.Count -eq 0){
          $valid=$false
        }
      }
  if ($valid){
    writeln  "Step 10. Valid" Green
  } else {
    writeln  "Step 10. WARNING FAILED, Check your network configuration." Red
    #$failures = $true
  }

if ($failures) {
  writeln  ""
  writeln  "========================================================================="
  writeln  "! You have failures, fix them first before installing Maestro. !" Red
  writeln  "========================================================================="
  writeln  ""

}
else {
  writeln  ""
  writeln  "You have no failures, proceed with the installation of Maestro." Green
  writeln  "See: https://docs.coveo.com/en/71/cloud-v2-developers/installing-maestro"
  writeln  ""

}