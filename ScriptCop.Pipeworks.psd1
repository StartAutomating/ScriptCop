@{
    WebCommand = @{
        "Test-Command" = @{
            HideParameter = "Command"
            RunOnline=$true
            FriendlyName = "Test a Command"
        }
        "Get-ScriptCopRule" = @{
            RunWithoutInput = $true
            RunOnline=$true
            FriendlyName = "ScriptCop Rules"
        }
        "Get-ScriptCopPatrol" = @{
            RunWithoutInput = $true
            RunOnline=$true
            FriendlyName = "ScriptCop Patrols"
        }
    }
    AnalyticsId = 'UA-24591838-3'
    CommandOrder = "Test-Command",
        "Get-ScriptCopRule",
        "Get-ScriptCopPatrol"

    Style = @{
        Body = @{
            'Font' = "14px/2em 'Rockwell', 'Verdana', 'Tahoma'"

        }
    }
    Logo = '/ScriptCop_125_125.png'
    AddPlusOne = $true
    TwitterId = 'jamesbru'
    Facebook = @{
        AppId = '250363831747570'
    }

    DomainSchematics = @{
        "ScriptCop.Start-Automating.com | Scriptcop.StartAutomating.com" =
            "Default"
    }

    AdSense = @{
        Id = '7086915862223923'
        BottomAdSlot = '6352908833'
    }

    AllowDownload = $true

    Technet = @{
        Category="Scripting Techniques"
        Subcategory="Writing Scripts"
        OperatingSystem="Windows 7", "Windows Server 2008", "Windows Server 2008 R2", "Windows Vista", "Windows XP", "Windows Server 2012", "Windows 8"
        Tag ='ScriptCop', 'Start-Automating', 'Static Analysis', 'Testing', 'Code Coverage'
        MSLPL=$true
        Summary="
ScriptCop is a tool to help sure your scripts are following the rules.  It performs static analysis on PowerShell scripts to help identify common problems.
"
        Url = 'http://gallery.technet.microsoft.com/ScriptCop-0896dd1e'
    }


    GitHub = @{
        Owner = "StartAutomating"
        Project = "ScriptCop"
        Url = 'https://github.com/StartAutomating/ScriptCop'
    }
}