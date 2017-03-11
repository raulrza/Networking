<#

.AUTHOR
Raul Bringas

.DATE
12-22-2016

.DESCRIPTION
This script will prompt the user for hostname(s) or ip(s) and will check for ICMP replies and RDP availability.

#>


Param(     
     [parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$Hostname
     )

# Loop through all of the Hostnames entered by the user and check each one for ICMP and RDP connectivity

ForEach($Host_Name in $Hostname){
        
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
                
                # RDP connection is successful set output color to green
                Write-Host -ForegroundColor Green "RDP`n"

                # Close the socket used to test RDP
                $RDP_Socket.Close()

        }
    }

Catch{
    
    # RDP connection to the host failed, output the RDP status as Red
    Write-Host -ForegroundColor Red  "RDP`n"
    
    }

}
