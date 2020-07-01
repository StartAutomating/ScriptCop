function Unregister-ScriptCopRule
{
    <#
    .Synopsis
        Unregisters a ScriptCop rule.
    .Description
        Unregisters a ScriptCop rule, prevent it from running
    .Example
        Unregister-ScriptCopRule -Name Test-DocumentationQuality
    .Link
        Register-ScriptCopRule
    #>
    [CmdletBinding(DefaultParameterSetName='Name')]
    [OutputType([Nullable])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="PSScriptAnalyzer misses the assignment")]
    param(
    # The name of the rule
    [Parameter(ParameterSetName='Name',Mandatory=$true)]
    [string]$Name,

    # The rule command
    [Parameter(ParameterSetName='Command',ValueFromPipeline=$true,Mandatory=$true)]
    [Management.Automation.CommandInfo]$Command
    )

    begin {
        # Declare rules structure if it does not exist
        if (-not $script:ScriptCopRules) {
            $script:ScriptCopRules = @{
                TestCommandInfo = @()
                TestCmdletInfo = @()
                TestScriptInfo = @()
                TestFunctionInfo = @()
                TestApplicationInfo=  @()
                TestModuleInfo = @()
                TestScriptToken = @()
                TestHelpContent = @()
            }
        }
    }

    process {
        if ($psCmdlet.ParameterSetName -eq 'Name') {
            #region Locate and Remove Rule by Name
            if ($script:ScriptCopRules) {
                @($script:ScriptCopRules |
                    ForEach-Object {
                        foreach ($v in $_.Values) { $V }
                    }) |
                    Where-Object {
                        $_.Name -eq $Name
                    } |
                    Unregister-ScriptCopRule

            }
            #endregion
        } elseif ($psCmdlet.ParameterSetName -eq 'Command') {
             #region Locate and Remove Command
             $toRemove = $script:ScriptCopRules.GetEnumerator() |
                    Where-Object {
                        $_.Value -contains $Command
                    }

            if ($toRemove) {
                foreach ($tr in $toRemove) {
                    $script:ScriptCopRules[$tr.Key] = @($script:ScriptCopRules[$tr.Key] | Where-Object { $_ -ne $Command })
                }
            }
            #endregion
        }

        # Output the new rules to debug when completed.
        Write-Debug ($scriptCopRules | Out-String)
    }
}
