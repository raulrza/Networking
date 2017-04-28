<#

Author: Raul Bringas

Purpose: This script will check Windows hosts for Uptime, ICMP, and RDP connectivity.  
         The hostnames will be either collected from a text file, or prompt the user 
         for manual input.Test-Connection will be used to ping the hosts twice, and 
         a TCP socket will be opened on default RDP port 3389 to test connectivity.  
         The result of the host check will be displayed to indicate status. 
         Host uptime will also be displayed.

        Output format:
        Host: hostname
        Uptime: x Days x Hours x Minutes x Seconds
        ICMP (Up = Responding to ICMP, Down = Not Responding to ICMP)
        RDP (Up = Accessible via RDP, Down = Not accessible via RDP)

        CSV File Format:
        $Host_Name,$HostUptimeCSVD,$HostUptimeCSVH,$HostUptimeCSVM,$ICMPState,$RDPState
        Host Name, Uptime Days, Hours, Minutes, ICMP (Up|Down), RDP (Up|Down)

        Output files:
        "c:\RDP_ICMP_Uptime_Log.txt" - Formatted with the same output from the console.
        "c:\RDP_ICMP_Uptime_Log.csv" - CSV format used to sort by uptime and RDP/ICMP status.


Date: 4/21/2017

#>

$DateTime = Get-Date

# Grab this info from user and use Test-Path to validate/prompt
$LogPath = "c:\RDP_ICMP_Uptime_Log"
$UptimeLog = "$LogPath.txt"

Function ScriptMode($Run_Mode, $Hosts_Text_File) {
    # Check if the script will be run interactively
    If ($Run_Mode -like "A"){         

        
        # Remove any duplicated host names
        $HostNames = Get-Content $Hosts_Text_File | Select -uniq
        
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

Function GetHostUptime ($Computer_Name){
    
    Try {
            $WMIQuery = GWMI Win32_OperatingSystem -Computer $Computer_Name
            $LBTime = $WMIQuery.ConvertToDateTime($WMIQuery.Lastbootuptime) 
            [TimeSpan]$HostUptime = New-TimeSpan $LBTime $(get-date) 

    }
    
    Catch {
    
            #Write-Output "Uptime: Not available" | Tee-Object -File $UptimeLog -append
            $HostUptime = "NA"
    }

    
    Return $HostUptime

}

Function CheckWindowsHosts ($HostNames){
    
    ForEach($Host_Name in $HostNames){
        
        Write-Output "Host: $Host_Name" | Tee-Object -File $UptimeLog -append

            # Check if the host is responding to ICMP requests
            If (Test-Connection -ComputerName $Host_Name -Count 2 -Quiet){
                
                $ICMPState = "Up"
                $Host_Uptime = GetHostUptime $Host_Name

                If ($Host_Uptime -eq "NA"){
                    
                    $HostUptimeCSVD = $Host_Uptime
                    $HostUptimeCSVH = $Host_Uptime
                    $HostUptimeCSVM = $Host_Uptime
                    Write-Output "Uptime: $Host_Uptime"
                
                } Else {
                
                        Write-Output "Uptime: $($Host_Uptime.days) Days $($Host_Uptime.hours) Hours $($Host_Uptime.minutes) Minutes $($Host_Uptime.seconds) Seconds" | Tee-Object -File $UptimeLog -append
                        $HostUptimeCSVD = $Host_Uptime.days
                        $HostUptimeCSVH = $Host_Uptime.hours
                        $HostUptimeCSVM = $Host_Uptime.minutes
                }

                    
            } Else {
                
                    $ICMPState = "Down"
                    $HostUptimeCSVD = "NA"
                    $HostUptimeCSVH = "NA"
                    $HostUptimeCSVM = "NA"

            }    

        Write-Output "ICMP - $ICMPState" | Tee-Object -File $UptimeLog -append

    # Create a new TCP object to test for RDP connectivity
    Try {
            # Create a new socket and attempt to connect to the host via RDP default port
            $RDP_Socket = New-Object System.Net.Sockets.TCPClient($Host_Name,3389)

		    If ($RDP_Socket -eq $null){

            # This indicates that the RDP connection failed, and will be caught by the catch statement

            } Else {
                
                # RDP connection is sucessful set output color to green
                $RDPState = "Up"

                # Close the socket used to test RDP
                $RDP_Socket.Close()

            }
        }

    Catch {
    
        # RDP connection to the host failed, output the RDP status as Red
        $RDPState = "Down"
    
        }
    
    Write-Output "RDP - $RDPState`n" | Tee-Object -File $UptimeLog -append
    Write-Output "" | Tee-Object -File $UptimeLog -append

    # Ouput variables in CSV friendly format
    # Host,Uptime,ICMP,RDP
    Write-Output "$Host_Name,$HostUptimeCSVD,$HostUptimeCSVH,$HostUptimeCSVM,$ICMPState,$RDPState" >> $UptimeLogCSV

    }

}

# Welcome message and prompt user for script run-mode
Write-Output "Welcome to the Windows Host Check Script: Check for ICMP and RDP connectivity.`n" | Tee-Object -File $UptimeLog -append
$RunMode = Read-Host "How would you like to run the script? `nA - Automated (Using a text file with host names)`nI - Interactive (Input host name manually)`n" 


If ($RunMode -like "A") { $HostsTextFile = Read-Host "Enter the path to a text file with hostnames to check:`n" }

$UptimeLogCSV = "$LogPath-CSV.txt"
Write-Output "Host,Uptime: Days,Hours,Minutes,ICMP,RDP" > $UptimeLogCSV

While ($true){
    
    $DateTime = Get-Date
    
    Write-Output "##############################################################################################" | Tee-Object -File $UptimeLog -append
    Write-Output "Start Date and Time: $DateTime" | Tee-Object -File $UptimeLog -append
    Write-Output "##############################################################################################" | Tee-Object -File $UptimeLog -append
    
    ScriptMode $RunMode $HostsTextFile

    Write-Output "Scan results have been saved to $LogPath.csv in CSV format..."
    Write-Output "Waiting 15 minutes before checking the hosts again!"
    

    Import-Csv $UptimeLogCSV | Export-CSV "$LogPath.csv" -NoTypeInformation
    Sleep 900

}