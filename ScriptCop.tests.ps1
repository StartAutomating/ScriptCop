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
        it 'Can test itself' {
            Get-Module ScriptCop | Test-Module
        }
    }
}
