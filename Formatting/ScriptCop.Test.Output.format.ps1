[OutputType('ScriptCop.Test.Output')]
param()
$testOutput = $_
$in = $_
$writeColor = 
    if ($testOutput.Passed) {
        if (-not $host.UI.SupportsVirtualTerminal) { "DarkGreen" } else { "Success" }
    } else {
        if (-not $host.UI.SupportsVirtualTerminal) { "Red" } else { "Error" }
    }
$testStatus = 
    if ($testOutput.Passed) {
        "+"
    } else {
        ""
    }

@(if (-not ($Request -and $response)) {

    $msg = "    [$testStatus] $($testOutput.TestCase)"
    if (-not $host.UI.SupportsVirtualTerminal) {
        Write-Host $msg -ForegroundColor $writeColor

        if ($test.Errors) {
            Write-Host "$($testOutput.Errors |Out-String)" -ForegroundColor $writeColor
        }
        ''

    } else {
        . $SetOutputStyle -foregroundColor $writeColor
        $msg
        #[Environment]::NewLine
        if ($testOutput.Errors) {
            
            $testOutput.Errors | Out-String -Width $host.UI.RawUI.BufferSize.Width
        }
        . $clearOutputStyle
    }
} else {
"
<div style='float:left;width:80%;font-size:1.11em'>
    <h4>
        $($testOutput.TestCase)
    </h4>
    $(if ($testOutput.Errors) {
"<pre>
$($testOutput.Errors | Out-String)
</pre>"
    })
</div>
<div style='float:right;width:20%;font-size:1.11em;text-align:right'>
    <span style='font-size:1.11em'>$testStatus</span>
</div>
<br style='clear:both' />
"
}) -join ''

