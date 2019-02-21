Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -force
Unblock-File -Path .\Step1_PreRequisitesCheck.ps1
Unblock-File -Path .\Step2_DockerInstallationCheck.ps1
Unblock-File -Path .\Step3_FinalInstallationCheck.ps1