# crawlingmodulechecks
Scripts to check the installation of the Crawling Modules.
Setting up the crawling modules requires (for now) some manual steps. In order to make sure all requirements and all processes are executed properly, these Powershell scripts will help.

## Installation
On your Virtual Machine, create a directory called: ```Check```.
Copy the powershell scripts in that directory.

## Before you start
Before you start, first open a Powershell window with Elevated rights on your Virtual Machine.
```
Start > Windows PowerShell > Run as Administrator
```
Navigate to the directory check.
```powershell
cd \check
```

## Step 1. Requirements check
The requirements are [documented](https://docs.coveo.com/en/23/cloud-v2-developers/requirements).

To check if your Virtual Machine conforms to the requirements:
```powershell
.\Step1_PreRequisitesCheck.ps1
```

The script will write the output to the console, and to the file Step1_Log.txt.

Only when all checks are valid, proceed to [Docker Installation](https://docs.coveo.com/en/96/cloud-v2-developers/installing-docker#installing-docker-enterprise-edition).

## Step 2. Docker Installation check
After docker is installed, the next script will check if the installation was succesfull.
```powershell
.\Step2_DockerInstallationCheck.ps1
```

The script will write the output to the console, and to the file Step2_Log.txt.
Only when all checks are valid, proceed to [Maestro Installation](https://docs.coveo.com/en/71/cloud-v2-developers/installing-maestro).

## Step 3. Final installation check
(Coming) When Maestro is installed, the Machine is connected to the Coveo Cloud Platform, and the workers are started.
The final installation check script will check if the virtual machine is working properly.
```powershell
.\Step3_FinalInstallationCheck.ps1
```

