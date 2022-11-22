Configuration WindowsUpdate {

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node localhost {

        Registry WindowsUpdateAUWUServer {
            Ensure = "Absent"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "UseWUServer"
            ValueData = "0"
            ValueType = "Dword"
        }

        Registry WindowsUpdateAUWUStatusServer {
            Ensure = "Absent"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "WUStatusServer "
            ValueData = "0"
            ValueType = "Dword"
        }

        Registry WindowsUpdateAUOptions {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "AUOptions"
            ValueData = "4"
            ValueType = "Dword"
        }

        Registry WindowsUpdateNoAU {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "NoAutoUpdate"
            ValueData = "0"
            ValueType = "Dword"
        }

        Registry WindowsUpdateNoAutoRebootWithLoggedOnUsers {
            Ensure = "Present"
            Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "NoAutoRebootWithLoggedOnUsers"
            ValueData = "1"
            ValueType = "Dword"
        }

    }
}