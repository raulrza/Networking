<# 

.AUTHOR
Raul Bringas

.DATE
04-24-2017

.VERSION
1.2

.DESCRIPTION
Ping Sweep utility that quickly tests connectivity on a range of IPs and resolves the corresponding DNS record.
A text file named "Non-RespondingIPs.txt" will be created with non responsive hosts in the C:\

.EXAMPLE
Input the first three octets ie (10.40.200): 10.44.5
Input the last octet start range ie (1): 1
Input the last octet end range ie (254): 4
Input the amount of ICMP requests per host (4): 2

.BUG FIX
There was an issue where the DNS name from the previous host would be printed for non-responding hosts.

#>

# Prompt the user for the first three octets, low/high range of the last octet, and ICMP request count
$FirstThreeOctets = Read-Host -Prompt 'Input the first three octets ie (10.40.200)'
$RangeLow = Read-Host -Prompt 'Input the last octet start range ie (1)'
$RangeHigh = Read-Host -Prompt 'Input the last octet end range ie (254)'
$ICMPCount = Read-Host -Prompt 'Input the amount of ICMP requests per host (4)'

# Convert the last octet range input by the user into an int for loop counters
$LastOctetLow = [int]$RangeLow
$LastOctetHigh = [int]$RangeHigh


Write-Host "Host is responding to ICMP" -ForegroundColor Green
Write-Host "Host is not responding to ICMP`n" -ForegroundColor Red

# Loop through the range of ips provided by the user
while ($LastOctetLow -le $LastOctetHigh) {

# Reconstruct the IP address using the user input FirstThreeOctet+LastOctetLow
$IP = "$FirstThreeOctets.$LastOctetLow"

# By default the text color is set to "Red" and "ICMP" to false
# These values will change depending on the result of Test-Connection
$FGColor = "Red"
$ICMP = $false
$DNS = "No DNS Record"

    # Check if the server is up using the Test-Connection cmdlet, this will return 'True' or 'False'
    If (Test-Connection -ComputerName $IP -Count $ICMPCount -Delay 1 -Quiet){
        $FGColor = "Green"
        $ICMP = $true
    }
        
    # Gather the DNS value of the current IP address
    Try { 
            $DNS = [System.Net.Dns]::GetHostByAddress($IP).Hostname
            Write-Host "$IP - $DNS" -ForegroundColor $FGColor
        }

    Catch [Exception] {
                         Write-Host "$IP - $DNS" -ForegroundColor $FGColor
                              
        }

             
# Output the IP address being tested along with it's status "Up" or "Down" indicated by the text color Green or Red, respectively.
#Write-Host "$IP - $DNS" -ForegroundColor $FGColor

$LastOctetLow++

    If ($ICMP -eq $false){
   
        Write-Output "$IP - $DNS" >> C:\Non-RespondingIPs.txt
    } 
       
}

PAUSE