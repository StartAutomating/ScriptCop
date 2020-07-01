#requires -Module Pester, ScriptCop

describe ScriptCop {
    context 'Static Analysis' {
        it 'Can enforce rules' {
            function foo {

            }

            Get-command foo |
                Test-Command -Rule Test-CommandNamingConvention |
                Select-Object -ExpandProperty Problem |
                should -BeLike *StandardVerb-CustomNoun*
        }
    }

    context 'Testing' {
        it 'Can reload and test itself' {
            $theModule = Get-Module ScriptCop
            Import-Module ($theModule |
                Split-Path | Join-Path -ChildPath ScriptCop.psd1) -Global -Force -PassThru |
                   Test-Module
        }
    }
}
