<#
  
.AUTHOR
Raul Bringas

.DATE   
12/21/2016

.VERSION
1.1

.DESCRIPTION

Cycle through SCOM Heartbeat/Shutdown email alerts in a particular folder and parse hostnames from the emails.
The hostnames will be used to check if ICMP and RDP are responding.
Emails should be scanned every 2 minutes or so to find any unresponsive Windows hosts.

.REQUIREMENTS

In order for this script to work you need a folder named 'Alerts' and a sub-folder named 'Critical'.
Alternatively, you could change the folder names below in the $SubjectLineHeartbeat & $SubjectLineShutdown
variables to match your particular Outlook Folders.

.BUG_FIXES

BUG_ID# 1: Resolved an unhandled exception when trying to check null Shutdown Hosts.
                                                          
#>

# Invoke the Outlook API, and create a namespace using the current user's mailbox
Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -comobject Outlook.Application
$NameSpace = $Outlook.GetNameSpace("MAPI")

<# 

.FUNCTION
CheckHost

.SYNOPSIS
Checks Host(s) for ICMP and RDP connectivity.

.DESCRIPTION
This function will check hosts for ICMP and RDP response. It takes a single host name as an input parameter. 

.PARAMETER $Host_Name
A single host name that has been parsed from the SCOM email alerts in the user's inbox.

.EXAMPLE
CheckHost $Hosts

#>


Function CheckHost($Host_Name) {
        # Check if the host is responding to ICMP requests
        If (Test-Connection -ComputerName $Host_Name -Count 2 -Quiet){
            
            Write-Host -ForegroundColor Yellow $Host_Name
            Write-Host -ForegroundColor Green "ICMP"
                    
        } Else {
                
                Write-Host -ForegroundColor Yellow $Host_Name
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

    Catch {
    
            # RDP connection to the host failed, output the RDP status as Red
            Write-Host -ForegroundColor Red  "RDP`n"
    
        }

}

<# 

.FUNCTION
GetHostFromSubject

.SYNOPSIS
Parse SCOM email subject line for individual host names. Call the CheckHost function with the individual host name.

.DESCRIPTION
Cycle through an array of SCOM alert email subject lines obtained from the user's inbox.  
Use whitespace as a delimiter and add the host to a string array.
Call the CheckHost function with the host name extracted from the email subject line.

.PARAMETER $SubjectLineArray
A string array that contains the entire SCOM subject lines extracted from the user's inbox.

.PARAMETER $DelimiterLength
This is an INT value that specifies how many white spaces should be skipped when parsing for host name.

.EXAMPLE
GetHostFromSubject $SubjectLineHeartbeat 1 

#>


Function GetHostFromSubject ($SubjectLineArray, $DelimiterLength) {

$HostCount = 0
While ($HostCount -lt $SubjectLineArray.Length){
    # Parse the Subject line by space and select the hostname (adjust depending on how many spaces before host name $DelimiterLength)
    $Hosts = ($SubjectLineArray[$HostCount] -split ' ')[$DelimiterLength]
    CheckHost $Hosts
    $HostCount += 1
   
   }

}

# Main loop, repeats host check every 2 minutes.
While ($true) {


    # This will check the current Outlook User's namespace for emails in the Inbox -> Alerts -> Critical folder for items with the word "New"
    $SubjectLineHeartbeat = $NameSpace.Folders.Item(1).Folders.Item('Alerts').Folders.Item('Critical').Items | Select Subject | Select-String -Pattern "New"
    
    # This will check the current Outlook User's namespace for emails in the Inbox -> Alerts folder for items with the word "Shutdown"
    $SubjectLineShutdown = $NameSpace.Folders.Item(1).Folders.Item('Alerts').Items | Select TaskSubject | Select-String -Pattern "Shutdown"

    # Trim the last character "}" since the host name is the last element in the subject for these alerts
    # The trim command does not set the array to $null instead check for an empty string " "    
    $SubjectLineShutdown = $SubjectLineShutdown -replace ".{1}$"

    # Get the current date and time before running the heartbeat host check
    $StartDateTime = Get-Date
    Write-Host -ForegroundColor DarkGray "Starting SCOM Heartbeat Host Check: " $StartDateTime

    # Call the function to parse the hostnames from email subject with a delimiter of 1
    If ($SubjectLineHeartbeat -eq $null) {

        Write-Host -ForegroundColor Yellow "There are no hosts to check at this time.`n"

    } Else {
                GetHostFromSubject $SubjectLineHeartbeat 1 
    }
    
    # Get the current date and time before running the shutdown host check
    $StartDateTime = Get-Date
    Write-Host -ForegroundColor DarkGray "Starting SCOM Shutdown Host Check: " $StartDateTime

    # Call the function to parse the hostnames from email subject with a delimiter of 5
    # BUG_ID #1: Handling exception thrown when $SubjectLineShutdown is empty or null.
    Try
    {
        GetHostFromSubject $SubjectLineShutdown 5
    }
    
    Catch
    {
        Write-Host -ForegroundColor Yellow "There are no hosts to check at this time.`n"
    }
   
     
# Wait 5 minutes, and then run again...
Write-Host "Waiting for 5 minutes before the next check..."
Sleep 300
}