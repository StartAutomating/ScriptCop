function Test-ForWriteProgressWithoutID
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
        $writeProgressFoundAt =@{}
        $lookingForId = $false
        $lastWriteProgress = $null
        foreach ($t in $ScriptToken) {
            if ($lookingForId -and $t.Type -eq 'CommandParameter') {
                if ($t.Content -eq '-ID') {
                    $lookingForId = $false
                    $writeProgressFoundAt.Remove($lastWriteProgress.Start)
                    $lastWriteProgress= $null
                } 
            }

            if ($lookingForId -and $t.Type -eq 'Command') {
                $lookingForId = $false 
            }

            if ($t.Content -eq 'Write-Progress' -and $t.Type -eq 'Command') {
                $writeProgressFoundAt[$t.Start] = $lastWriteProgress  = $t 
                $lookingForId = $true
            }
            
        }
        

        if ($writeProgressFoundAt.Count) {
            $writeprogreslocations = $writeProgressFoundAt.Values | Sort-Object StartLine |  ForEach-Object { "($($_.StartLine + 1), $($_.StartColumn))" }
            Write-Error "Write-Progress should have an ID (if it's not there, progress messages from nested functions can clobber each other).  Write-Progres is lacking an id at: $($writeprogreslocations -join ' and ')"
        }        
    }
}