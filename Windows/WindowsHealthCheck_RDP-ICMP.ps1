<#

Author: Raul Bringas

Purpose: This script will check Windows hosts for ICMP and RDP connectivity.  The hostnames
        will be either collected from a text file, or prompt the user for manual input.
        Test-Connection will be used to ping the hosts twice, and an TCP socket will be
        opened on default RDP port 3389 to test connectivity.  The result of the host check
        will be displayed and color coordinated to indicate status.

        Output format:
        Host: hostname
        ICMP (Green = Responding to ICMP, Red = Not Responding to ICMP)
        RDP (Green = Accessible via RDP, Red = Not accessible via RDP)


#>

Function ScriptMode($Run_Mode) {
    # Check if the script will be run interactively
    If ($Run_Mode -like "A"){         

        $HostsTextFile = Read-Host "Enter the path to a text file with hostnames to check:`n"
        
        # Remove any duplicated host names
        $HostNames = Get-Content $HostsTextFile | Select -uniq
        
        # Call the function to check the collected hostnames for ICMP and RDP connectivity
        CheckWindowsHosts $HostNames
                                          
    } Else {
                
                Write-Host -ForegroundColor Yellow "`nThe script will run interactively, please enter host names one at a time and press ENTER."
                CollectHostNames

            }    
}

Function CollectHostNames () {

    Param(     
     [parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$HostNames
     )
     
     # Remove any duplicated host names
     $HostNames = $HostNames | Select -uniq

     # Call the function to check the collected hostnames for ICMP and RDP connectivity
     CheckWindowsHosts $HostNames
}

Function CheckWindowsHosts ($HostNames){
    
    ForEach($Host_Name in $HostNames){
        
        # Check if the host is responding to ICMP requests
        If (Test-Connection -ComputerName $Host_Name -Count 2 -Quiet){
            
            Write-Host -ForegroundColor Yellow "Host: $Host_Name"
            Write-Host -ForegroundColor Green "ICMP"
                    
        } Else {
                
                Write-Host -ForegroundColor Yellow "Host: $Host_Name"
                Write-Host -ForegroundColor Red "ICMP"     
        }    

    # Create a new TCP object to test for RDP connectivity
    Try {
            # Create a new socket and attempt to connect to the host via RDP default port
            $RDP_Socket = New-Object System.Net.Sockets.TCPClient($Host_Name,3389)

		    If ($RDP_Socket -eq $null){

            # This indicates that the RDP connection failed, and will be caught by the catch statement

            } Else {
                
                # RDP connection is sucessful set output color to green
                Write-Host -ForegroundColor Green "RDP`n"

                # Close the socket used to test RDP
                $RDP_Socket.Close()

            }
        }

    Catch {
    
        # RDP connection to the host failed, output the RDP status as Red
        Write-Host -ForegroundColor Red  "RDP`n"
    
        }

    }

}


# Welcome message and prompt user for script run-mode
Write-Host "Welcome to the Windows Host Check Script: Check for ICMP and RDP connectivity.`n"
$RunMode = Read-Host "How would you like to run the script? `nA - Automated (Using a text file with host names)`nI - Interactive (Input host name manually)`n"

# This function determines if the script is run automatically or interactively
ScriptMode $RunMode