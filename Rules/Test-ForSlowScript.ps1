function Test-ForSlowScript
{
    #region     ScriptTokenValidation Parameter Statement
    [OutputType([Nullable])]
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
        # Find any GroupStart tokens that are @(, 
        # - then find the preceeding variable.
        # - then find all instances of that variable using +=

        $PotentiallySlowVariables = @{}


        $VariablesIKnowToBeSlow = New-Object Collections.ArrayList
        

        $GetContentAliases = Get-Alias | 
            Where-Object {$_.ResolvedCommand -like "Get-Content" } |
            Select-Object -ExpandProperty Name

        $AddContentAliases = Get-Alias | 
            Where-Object {$_.ResolvedCommand -like "Add-Content" } |
            Select-Object -ExpandProperty Name
        for ($i = 0; $i -lt $ScriptToken.count; $i++) {
            $t = $ScriptToken[$i]
            if ($t.Type -eq 'GroupStart' -and $t.Content -eq '@(') {
                # List Start Found


                for ($j = $i -1; $j -ge 0; $j--) {
                    if ($ScriptToken[$j].Type -eq 'Member') {                        
                        break
                    }
                    if ($ScriptToken[$j].Type -eq 'Variable') {
                        $PotentiallySlowVariables[$scriptToken[$j].Content]= $scriptToken[$j]
                        break
                    }
                }
            }


            if ($t.Type -eq 'Operator' -and $t.Content -eq '+=') {
                # += found.  Walk back and see if we know the variable
                
                for ($j = $i -1; $j -ge 0; $j--) {
                    if ($ScriptToken[$j].Type -eq 'Variable') {
                        if ($PotentiallySlowVariables.ContainsKey($ScriptToken[$j].Content)) {
                            # We've found an addition we don't like
                            # Tack this variable onto the list of errors
                            $null = $VariablesIKnowToBeSlow.Add($ScriptToken[$j].Content)
                        }
                        break
                    }
                }
                
                
            }


            if (($t.Type -eq 'Command' -and $t.Content -eq 'Get-Content') -or
                ($t.Type -eq 'Command' -and $GetContentAliases -contains $t.Content)) {
                Write-Error "Get-Content is not exactly fast.  [IO.File]::ReadAllText or [IO.File]::ReadAllBytes would be a better choice."                        
            }


            if (($t.Type -eq 'Command' -and $t.Content -eq 'Add-Content') -or 
                ($t.Type -eq 'Command' -and $AddContentAliases -contains $t.Content)) {
                Write-Error "Add-Content is abysmally slow.  Try [io.file]::AppendAllText"                        
            }
        
        }    
        
        
        foreach ($var in $VariablesIKnowToBeSlow) {
            if (-not $ScriptTokenCommand.Parameters.$var) {
                Write-Error "$var is an array, and you append to it with +=.  Since arrays in .NET are immutable (they never change), this causes the list to be recreated, and gets REALLY slow.  A better alternative would be using an ArrayList."                        
            }
            
        }                         

    }
   
} 
 
