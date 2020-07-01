[OutputType('ScriptCop.Test.Pass.Output')]
param()

$testPassOutput = $_

$writeColor = 
    if ($_.Passed) {
        if (-not $host.UI.SupportsVirtualTerminal) { "DarkGreen" } else { "Success" } 
    } else {
        if (-not $host.UI.SupportsVirtualTerminal) { "Red" } else { "Error" }
    }
$testStatus = 
    if ($_.Passed) {
        "+"
    } else {
        "-"
    }



@(if (-not ($request -and $response)) {
    $msg = " [$testStatus] $($testPassOutput.TestPass)"
    if (-not $host.UI.SupportsVirtualTerminal) {
        Write-Host " "
        Write-Host "$Msg" -ForegroundColor $writeColor -NoNewline
        Write-Host " "
        $null= ($testPassOutput.Results | Out-String)
        ''
    } else {
        [Environment]::NewLine
        . $setOutputStyle -foregroundColor $writeColor
        "$Msg"
        . $clearOutputStyle
        [Environment]::NewLine
        $($testPassOutput.Results | Out-String -Width $host.UI.RawUI.BufferSize.Width).Trim()
    }
} else {
    "<div style='background-color:$writeColor;color:#ffffff'>
        <div style='float:left;width:20%;font-size:1.22em'>
            <h3>
              $($_.TestPass)
            </h3>
        </div>
        <div style='float:right;width:20%;text-align:right;'>
            <span style='color:#ffffff;font-size:1.22em'>$testStatus</span>
        </div>
        <br style='clear:both'/>
        <div style='width:80%;margin-left:20%'>
            $($_.Results | Out-html)
        </div>
    </div>
    "
}) -join ''
