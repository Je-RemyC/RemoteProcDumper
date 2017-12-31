#############################################################################################################################################
# Remote Proc dumper
# 
#############################################################################################################################################


# Specify the server to target, the process to dump and the property to sort by


[CmdletBinding()]
Param (
  [Parameter(Mandatory=$True,Position=0)]
  [string]$RemoteServer,

  [Parameter(Mandatory=$True,Position=1)]
  [string]$ProcessToDump,

  [Parameter(Mandatory=$True,Position=2)]
  [string]$ObjectToSort

)

$username = "Enter username"
$password = "Enter password" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password


# Invoke-Command takes the Remote Server, Process To Dump and the Object To Sort and returns a process ID 


$GetProcessId = Invoke-Command -ComputerName $RemoteServer -Credential $cred -scriptblock { param($ObjectToSort,$ProcessToDump)

   get-process | Where-Object {$_.ProcessName -like "$ProcessToDump"} | Sort-object $ObjectToSort -Descending | select -index 0 | Select -ExpandProperty Id

    } -ArgumentList $ObjectToSort,$ProcessToDump

    $GetProcessId = $ProcessID

        write-host "Process to dump is $ProcessToDump and the Process Id is $ProcessID"


# Once the ProcessID has been grabbed, make a persistent connectiont to the remote server using PSSEsison


$PSSession = New-PSSession -ComputerName $RemoteServer -Credential $cred


# Using the PSSession, create a mapped network drive on the remote server

Function MapNetworkDrive { 

$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
$EnterPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
Net Use Q: "\\file-server\userdata\users\$env:username\downloads" /user:system\$env:username $EnterPassword

}

        MapNetworkDrive


# Take the Prcoess ID, pipe it to Proc dump and output the dump to the mapped network drive

Function Dump {

Invoke-Command -Session $PSSession -scriptblock { param($ProcessID,$ProcessToDump)

    &cmd /c 'C:\Program Files\SysInternals\procdump64.exe' -ma $ProcessID "Q:\$env:COMPUTERNAME-$ProcessToDump.dmp" -accepteula

    } -ArgumentList $ProcessID, $ProcessToDump

}

        Dump


# Disconnect the session

Function DisConnect {
  
$PSSessionName = Get-PSSession

$RemovePSSession = $PSSessionName | Select -expandproperty ComputerName

Remove-PSSession -ComputerName $RemovePSSession 

}

        DisConnect