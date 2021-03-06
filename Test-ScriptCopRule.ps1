﻿function Test-ScriptCopRule
{
    [CmdletBinding(DefaultParameterSetName='TestCommandInfo')]
    param(
    [Parameter(ParameterSetName='TestCommandInfo',Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $CommandInfo
    )

    process {
        <#

        Only 3 types of commands can possibly be ScriptCopRules:

        - FunctionInfo
        - CmdletInfo
        - ExternalScriptInfo

        #>


        if ($CommandInfo -isnot [Management.Automation.FunctionInfo] -and
            $CommandInfo -isnot [Management.Automation.CmdletInfo] -and
            $CommandInfo -isnot [Management.Automation.ExternalScriptInfo]
        ) {
            Write-Error "$CommandInfo is not a function, cmdlet, or script"
            return
        }


        <#

        The parameter sets must have a specific name.

        The commands may have more than one parameter set.


        These parameter sets indicate the command can find problems

        - TestCommandInfo
        - TestCmdletInfo
        - TestScriptInfo
        - TestFunctionInfo
        - TestApplicationInfo
        - TestModuleInfo
        - TestScriptToken
        - TestHelpContent

        These parameter sets indicate the command can fix problems

        - RepairScriptCop
        #>


        $parameterSetNames = 'TestCommandInfo','TestCmdletInfo','TestScriptInfo',
            'TestFunctionInfo','TestApplicationInfo','TestModuleInfo',
            'TestScriptToken','TestHelpContent'

        $matchingParameterSets = $CommandInfo.ParameterSets |
            Where-Object {
                $parameterSetNames -contains $_.Name
            }

        if (-not $matchingParameterSets) {
            $ofs = ", "
            Write-Error "$CommandInfo could not be a script cop rule because it does not have any of the correct parameter sets:
$parameterSetNames
"
            return
        }

        foreach ($matchingParameterSet in $matchingParameterSets) {
            switch ($matchingParameterSet.Name)
            {
                TestCommandInfo {
                    $hasCommandParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'CommandInfo' -and
                        $_.ParameterType -eq [Management.Automation.CommandInfo]
                    }
                    if (-not $hasCommandParameter) {
                        Write-Error 'The TestCommandInfo parameter set does not have a CommandInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestFunctionInfo {
                    $hasFunctionParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'FunctionInfo' -and
                        $_.ParameterType -eq [Management.Automation.FunctionInfo]
                    }
                    if (-not $hasFunctionParameter) {
                        Write-Error 'The TestFunctionInfo parameter set does not have a FunctionInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestModuleInfo {
                    $hasModuleParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ModuleInfo' -and
                        $_.ParameterType -eq [Management.Automation.PSModuleInfo]
                    }
                    if (-not $hasModuleParameter) {
                        Write-Error 'The TestModuleInfo parameter set does not have a ModuleInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestCmdletInfo {
                    $hasCmdletParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'CmdletInfo' -and
                        $_.ParameterType -eq [Management.Automation.CmdletInfo]
                    }
                    if (-not $hasCmdletParameter) {
                        Write-Error 'The TestCmdletInfo parameter set does not have a CmdletInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestApplicationInfo {
                    $hasApplicationParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ApplicationInfo' -and
                        $_.ParameterType -eq [Management.Automation.ApplicationInfo]
                    }
                    if (-not $hasApplicationParameter) {
                        Write-Error 'The TestApplicationInfo parameter set does not have a ApplicationInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestScriptInfo {
                    $hasScriptParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ScriptInfo' -and
                        $_.ParameterType -eq [Management.Automation.ExternalScriptInfo]
                    }
                    if (-not $hasScriptParameter) {
                        Write-Error 'The TestScriptInfo parameter set does not have a ScriptInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestHelpContent {
                    $hasScriptParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'HelpContent'
                    }
                    if (-not $hasScriptParameter) {
                        Write-Error 'The TestHelpContent parameter set does not have a HelpContent parameter, or it is not the correct type'
                        return
                    }
                }

                TestScriptToken {
                    $hasCommandParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ScriptToken' -and
                        $_.ParameterType -eq [Management.Automation.PSToken[]]
                    }
                    if (-not $hasCommandParameter) {
                        Write-Error 'The TestScriptToken parameter set does not have a ScriptToken parameter, or it is not the correct type'
                        return
                    }
                }
            }
        }
    }
}
