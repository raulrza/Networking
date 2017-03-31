# This helper function uses RegEx to validate IP addresses.


$IP_RegEx = "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"

function ValidateIP ($IP_Addr){
        If ($IP_Addr -match $IP_RegEx) {
			
            return $IP_Addr
         
         } Else {
            
                Write-Host -ForegroundColor Red "Invalid IP address"
			    $IP = Read-Host "Enter a valid IP (x.x.x.x)"
			    ValidateIP ($IP)
         }
}

# Example
$Server_IP = Read-Host "IP (x.x.x.x)"
$Server_IP = ValidateIP ($Server_IP)