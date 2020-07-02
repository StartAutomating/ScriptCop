function Test-ForUnusedVariable
{
    #region     ScriptTokenValidation Parameter Statement
    param(
    <#
    This parameter will contain the tokens in the script, and will be automatically
    provided when this command is run within ScriptCop.

    This parameter should not be used directly, except for testing purposes.
    #>
    [Parameter(ParameterSetName='TestScriptToken',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSToken[]]
    $ScriptToken,

    <#
    This parameter will contain the command that was tokenized, and will be automatically
    provided when this command is run within ScriptCop.

    This parameter should not be used directly, except for testing purposes.
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.CommandInfo]
    $ScriptTokenCommand,

    <#
    This parameter contains the raw text of the script, and will be automatically
    provided when this command is run within ScriptCop

    This parameter should not be used directly, except for testing purposes.
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $ScriptText
    )
    #endregion  ScriptTokenValidation Parameter Statement

    process {
        $variablesAssignedAt = @{}
        $variablesReferencedAt = @{}
        $parametersAssignedAt = @{}
        $inParamBlock = $false
        $parenCount = 0
        $lastTokenWasVariable = $false
        foreach ($token in $scriptToken) {
            if ($token.Type -eq 'Keyword' -and $token.Content -eq 'param') {
                if (-not ($foreach.MoveNext())) { break }
                $parenCount = 1
                $inParamBlock = $true
                continue
            }
            if ($inParamBlock -and $token.Type -like 'Group*') {
                if ($token.Content -eq ')') { $parenCount-- }
                if ($token.Content -eq '(') { $parenCount++ }
                if ($parenCount -eq 0) { $inParamBlock = $false }
            }
            if ($lastTokenWasVariable -and -not $inParamBlock) {
                $variableName = $lasttoken.Content
                if ($token.Content -eq '=') {
                    if (-not ($variablesAssignedAt[$variableName])) {
                        $variablesAssignedAt[$variableName] = @()
                    }
                    $variablesAssignedAt[$variableName] += $lastToken
                } else {
                    if (-not ($variablesReferencedAt[$variableName])) {
                        $variablesReferencedAt[$variableName] = @()
                    }
                    $variablesReferencedAt[$variableName] += $lastToken
                }
                $lastTokenWasVariable = $false

            }

            if ($token.Type -eq 'Variable') {
                $variableName = $token.Content
                $lastToken = $token
                $lastTokenWasVariable = $true
            } elseif ($token.Type -eq 'string') {
                $variableRefType = '\$[{]*(?<variable>\w{1,})[}]*', '\@[{]*(?<variable>\w{1,})[}]*'
                foreach ($vrt in $variableRefType) {
                    $regex = New-Object Regex $vrt, 'Multiline, IgnoreCase'
                    foreach ($match in $regex.Matches($token.Content)) {
                        if (-not $match) { continue }
                        $variableName = $match.Value.Replace('$', '').Replace('@', '').Replace('{','').Replace('}','')
                        if (-not ($variablesReferencedAt[$variableName])) {
                            $variablesReferencedAt[$variableName] = @()
                        }
                        $variablesReferencedAt[$variableName] += $token
                    }
                }
            }
        }

        foreach ($variableName in $variablesAssignedAt.Keys) {
            # built in variables that are often set to do other things get a pass
            if ('null', 'ofs' -contains $variableName) { continue }
            # So do preference variables
            if ($variableName -like "*Preference") { continue }
            if ($variableName -like 'global:*' -or $variableName -like 'script:*') { continue }

            # Script: assignments do as well, since they could be caching
            if ($variablename -like "script:*") {continue }
            if (-not $variablesReferencedAt[$variableName]) {
                $assignedAt = $variablesAssignedAt[$variableName]
                $assignedAtString = ($assignedAt | Select-Object @{
                    Name = 'Line'
                    Expression = { $_.StartLine}
                }, @{
                    Name = 'Column'
                    Expression = { $_.StartColumn}
                }) -join
                    " and " -ireplace
                    ';', '' -ireplace
                    '@{', '' -ireplace
                    '}', ''
                Write-Error "`$$variableName is assigned to but never used.  It is assigned at $assignedAtString"
            }
        }
   }
}