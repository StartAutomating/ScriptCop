[Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ModuleManifestQuality*", "", Justification="FileList is unimportant")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ForSlowScript", "", Justification="Performance is not a priority")]
param()
Set-StrictMode -Off

#region Script Cop Rule Commands
. $psScriptRoot\Get-ScriptCopRule.ps1
. $psScriptRoot\Register-ScriptCopRule.ps1
. $psScriptRoot\Test-ScriptCopRule.ps1
. $psScriptRoot\Unregister-ScriptCopRule.ps1
#endregion Script Cop Rule Commands

Export-ModuleMember -Function Get-ScriptCopRule, Register-ScriptCopRule, Unregister-ScriptCopRule

#region Script Cop Fixer Commands
. $psScriptRoot\Get-ScriptCopFixer.ps1
. $psScriptRoot\Register-ScriptCopFixer.ps1
. $psScriptRoot\Test-ScriptCopFixer.ps1
. $psScriptRoot\Unregister-ScriptCopFixer.ps1
#endregion Script Cop Fixer Commands
Export-ModuleMember -Function Get-ScriptCopFixer, Register-ScriptCopFixer, Unregister-ScriptCopFixer

#region Patrol Functions
. $psScriptRoot\Get-ScriptCopPatrol.ps1
. $psScriptRoot\Register-ScriptCopPatrol.ps1
. $psScriptRoot\Save-ScriptCopPatrol.ps1
. $psScriptRoot\Unregister-ScriptCopPatrol.ps1
#endregion
Export-ModuleMember -Function Get-ScriptCopPatrol, Register-ScriptCopPatrol, Unregister-ScriptCopPatrol

#region General Purpose Functions
. $psScriptRoot\Get-FunctionFromScript.ps1
. $psScriptRoot\Get-ScriptToken.ps1
#endregion

#region Command Coverage
. $psScriptRoot\Disable-CommandCoverage.ps1
. $psScriptRoot\Enable-CommandCoverage.ps1
. $psScriptRoot\Get-CommandCoverage.ps1
#endregion


#region Major exported commands
. $psScriptRoot\Test-Command.ps1
. $psScriptRoot\Repair-Command.ps1
. $psScriptRoot\Show-ScriptCoverage.ps1
. $psScriptRoot\Test-Module.ps1


Export-ModuleMember -Function Test-Command, Test-Module,Repair-Command, Show-ScriptCoverage, Enable-CommandCoverage, Disable-CommandCoverage,Get-CommandCoverage
#endregion

#region Import Rules From Rules Directory
$RuleFiles = [IO.Directory]::GetFiles("$psScriptRoot\Rules")


$RuleScripts =
    foreach ($_ in $RuleFiles) {
        if (($_ -as [IO.FileInfo]).Extension -eq '.ps1') {
            $ExecutionContext.SessionState.InvokeCommand.GetCommand($_, 'ExternalScript')
        }
    }


foreach ($_ in $RuleScripts) {
    Test-ScriptCopRule -ErrorAction SilentlyContinue -ErrorVariable RuleImportError -CommandInfo $_
    @(if ($RuleImportError) {
        # Ok, see if it contains functions
        $functionOnly = Get-FunctionFromScript -ScriptBlock ([ScriptBlock]::Create($_.ScriptContents))
        . $_
        $cmds = @()
        foreach ($f in $functionOnly) {
            #. ([ScriptBlock]::Create($f))
            $matched = $f -match "function ((\w+-\w+)|(\w+))"
            if ($matched -and $matches[1]) {
                $foundCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand("$($matches[1])", 'Function')
                if ($foundCmd) {
                    $cmds += $foundCmd
                }
                #$cmds+=Get-Command $matches[1] -ErrorAction SilentlyContinue
            }
        }

        foreach ($cmd in $cmds) {
            Test-ScriptCopRule -ErrorAction SilentlyContinue -ErrorVariable RuleImportError2 -CommandInfo $cmd

            if ($ruleImportError2) {
                Write-Verbose ($RuleImportError2 |Out-String)
            } else {
                $cmd
            }
        }

        if (-not $RuleImportError2) {
            Write-Debug ($RuleImportError |Out-String)
        }
    } else {
        $_
    }) | Register-ScriptCopRule
}

<#
Get-ChildItem $psScriptRoot\Rules |
    Get-Command { $_.Fullname } -ErrorAction SilentlyContinue |
    Where-Object {
        $_ -is [Management.Automation.ExternalScriptInfo]
    } |
    Foreach-Object -Verbose:($Verbose -ne 'SilentlyContinue') {
        Write-Verbose "Attempting to Import $_"
        Test-ScriptCopRule -ErrorAction SilentlyContinue -ErrorVariable RuleImportError -CommandInfo $_
        if ($RuleImportError) {
            # Ok, see if it contains functions
            $functionOnly = Get-FunctionFromScript -ScriptBlock ([ScriptBlock]::Create($_.ScriptContents))
            . $_
            $cmds = @()
            foreach ($f in $functionOnly) {
                #. ([ScriptBlock]::Create($f))
                $matched = $f -match "function ((\w+-\w+)|(\w+))"
                if ($matched -and $matches[1]) {
                    $foundCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand("$($matches[1])", 'Function')
                    if ($foundCmd) {
                        $cmds += $foundCmd
                    }
                    #$cmds+=Get-Command $matches[1] -ErrorAction SilentlyContinue
                }
            }

            $cmds |
                Where-Object {
                    Test-ScriptCopRule -ErrorAction SilentlyContinue -ErrorVariable RuleImportError2 -CommandInfo $_

                    if ($ruleImportError2) {
                        Write-Verbose ($RuleImportError2 |Out-String)
                    } else {
                        $_
                    }
                } |
                Register-ScriptCopRule

            if (-not $RuleImportError2) {
                Write-Debug ($RuleImportError |Out-String)
            }
        } else {
            $_ | Register-ScriptCopRule
        }

    }
#>
$FixerFiles = [IO.Directory]::GetFiles("$psScriptRoot\Fixers")


$FixerScripts =
    foreach ($_ in $FixerFiles) {
        if (($_ -as [IO.FileInfo]).Extension -eq '.ps1') {
            $ExecutionContext.SessionState.InvokeCommand.GetCommand($_, 'ExternalScript')
        }
    }

foreach ($_ in $FixerScripts) {
    Write-Verbose "Attempting to Import $_"
    Test-ScriptCopFixer -ErrorAction SilentlyContinue -ErrorVariable RuleImportError -CommandInfo $_
    @(if ($RuleImportError) {
        Write-Verbose ($RuleImportError |Out-String)
        # Ok, see if it contains functions
        $functionOnly = Get-FunctionFromScript -ScriptBlock ([ScriptBlock]::Create($_.ScriptContents))
        . $_
        $cmds = @()
        foreach ($f in $functionOnly) {
            #. ([ScriptBlock]::Create($f))
            $matched = $f -match "function ((\w+-\w+)|(\w+))"
            if ($matched -and $matches[1]) {
                $foundCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand("$($matches[1])", 'Function')
                if ($foundCmd) {
                    $cmds += $foundCmd
                }
                #$cmds+=Get-Command $matches[1] -ErrorAction SilentlyContinue
            }
        }

        foreach ($cmd in $cmds) {
            Test-ScriptCopFixer -ErrorAction SilentlyContinue -ErrorVariable RuleImportError2 -CommandInfo $cmd

            if ($ruleImportError2) {
                Write-Verbose ($RuleImportError2 |Out-String)
            } else {
                $cmd
            }
        }

        if (-not $RuleImportError2) {
            Write-Verbose ($RuleImportError1 |Out-String)
        }
    } else {
        $_
    }) | Register-ScriptCopFixer

}


Get-ChildItem $psScriptRoot\Fixers |
    Get-Command { $_.Fullname } -ErrorAction SilentlyContinue |
    Where-Object {
        $_ -is [Management.Automation.ExternalScriptInfo]
    } |
    Foreach-Object {
        Write-Verbose "Attempting to Import $_"
        Test-ScriptCopFixer -ErrorAction SilentlyContinue -ErrorVariable RuleImportError -CommandInfo $_
        if ($RuleImportError) {
            Write-Verbose ($RuleImportError |Out-String)
            # Ok, see if it contains functions
            $functionOnly = Get-FunctionFromScript -ScriptBlock ([ScriptBlock]::Create($_.ScriptContents))
            . $_
            $cmds = @()
            foreach ($f in $functionOnly) {
                #. ([ScriptBlock]::Create($f))
                $matched = $f -match "function ((\w+-\w+)|(\w+))"
                if ($matched -and $matches[1]) {
                    $foundCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand("$($matches[1])", 'Function')
                    if ($foundCmd) {
                        $cmds += $foundCmd
                    }
                    #$cmds+=Get-Command $matches[1] -ErrorAction SilentlyContinue
                }
            }

            $cmds|
                Where-Object {
                    Test-ScriptCopFixer -ErrorAction SilentlyContinue -ErrorVariable RuleImportError2 -CommandInfo $_

                    if ($ruleImportError2) {
                        Write-Verbose ($RuleImportError2 |Out-String)
                    } else {
                        $_
                    }
                } |
                Register-ScriptCopFixer

            if (-not $RuleImportError2) {
                Write-Verbose ($RuleImportError1 |Out-String)
            }
        } else {
            $_ | Register-ScriptCopFixer
        }

    }
#endregion

#region Import Patrols
Get-ChildItem $psScriptRoot\Patrols -ErrorAction SilentlyContinue -Filter *.patrol.psd1 |
    ForEach-Object {
        $fullPath = $_.fullname
        $name = $_.Name.Replace(".patrol.psd1", "")
        $patrolContent = try { ([PowerShell]::Create().AddScript("
            `$executionContext.SessionState.LanguageMode = 'RestrictedLanguage'
            $([IO.File]::ReadAllText($fullPath))
        ").Invoke())[0] } catch {
            Write-Debug "Error Importing $fullpath : $($_ | Out-string)"
        }

        if ($patrolContent) {
            $patrolContent.Name = $name
            Register-ScriptCopPatrol @patrolContent
        }
    }
#endregion
