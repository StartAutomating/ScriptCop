function Register-ScriptCopRule
{
    <#
    .Synopsis
        Registers a new script cop rule
    .Description
        Registers a new script cop rule.
        You can define custom script cop rules and use this command to register them on the fly.
    .Link
        Unregister-ScriptCopRule
    .Example
        Register-ScriptCopRule -File .\ARuleScript.ps1
    .Example
        Register-ScriptCopRule -Command (Get-Command ARule)
    #>
    [CmdletBinding(DefaultParameterSetName='Command')]
    [OutputType([Nullable])]
    param(
    # The Rule command.  To Get Commandinfo, use the results of Get-Command
    [Parameter(ParameterSetName='Command',
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Rule,

    # A file containing a script cop rule.
    [Parameter(ParameterSetName='File',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Alias('FullName')]
    [String]
    $File
    )

    begin {
        #declare rules structure if it doesn't exist
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
        if ($psCmdlet.ParameterSetName -eq 'Command') {
            #region Register command
            $Rule |
                Test-ScriptCopRule -ErrorVariable Issues |
                Out-Null

            if ($Issues) { return }

            $parameterSetNames = 'TestCommandInfo','TestCmdletInfo','TestScriptInfo',
                'TestFunctionInfo','TestApplicationInfo','TestModuleInfo',
                'TestScriptToken','TestHelpContent'

            $Rule.ParameterSets |
                Where-Object {
                    $parameterSetNames -contains $_.Name
                } |
                ForEach-Object {
                    $ScriptCopRules[$_.Name] += $Rule
                    $ScriptCopRules[$_.Name] =
                        @($ScriptCopRules[$_.Name] |
                            Select-Object -Unique)
                }

            Write-Debug ($scriptCopRules | Out-String)
            #endregion
        } elseif ($psCmdlet.ParameterSetName -eq 'File') {
            #region Register File
            $command = Get-Item $File |
                Select-Object -ExpandProperty Fullname |
                Get-Command
            if (-not $command) { return }
            $command | Register-ScriptCopRule
            #endregion
        }

    }
}

