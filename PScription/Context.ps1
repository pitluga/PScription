function Create-TestObject([string]$name, [scriptblock]$testDefinition) {
    $test = New-Object PSObject
    $test | Add-Member -MemberType NoteProperty -Name Name -Value $name
    $test | Add-Member -MemberType NoteProperty -Name TestScript -Value $testDefinition
    return $test
}

function Create-ContextObject([string]$contextName) {
    $context = New-Object PSObject
    $context | Add-Member -MemberType NoteProperty -Name Name -Value $contextName
    $context | Add-Member -MemberType NoteProperty -Name SetUpScript -Value {}
    $context | Add-Member -MemberType NoteProperty -Name TearDownScript -Value {}
    $context | Add-Member -MemberType NoteProperty -Name Tests -Value @()
    $context | Add-Member -MemberType ScriptMethod -Name Execute -Value { 
        param($aggregator)
        foreach($currentTest in $this.Tests) {
            try {
                try {
                    . $this.SetUpScript
                    . $currentTest.TestScript
                }
                finally {
                    . $this.TearDownScript
                }
                $aggregator.ReportSuccess($this.Name)
            }
            catch [PScription.AssertionFailedException] {
                $aggregator.ReportFailure($currentTest.Name, $_)
            }
            catch {
                $aggregator.ReportError($currentTest.Name, $_)
            }
        } 
    }
    return $context
}

function New-RxTest([string]$name, [scriptblock]$testDefinition) {
    $test = Create-TestObject $name $testDefinition
    $test | Add-Member -MemberType ScriptMethod -Name Execute -Value { 
        param($aggregator)
        try {
            &$this.TestScript
            $aggregator.ReportSuccess($this.Name)
        }
        catch [PScription.AssertionFailedException] {
            $aggregator.ReportFailure($this.Name, $_)
        }
        catch {
            $aggregator.ReportError($this.Name, $_)
        }
    }
    $script:tests += $test
}
New-Alias Test New-RxTest

function New-RxContext([string]$contextName, [scriptblock]$contextDefinition) {
    $context = Create-ContextObject $contextName
    
    function SetUp([scriptblock]$setup) {
        $context.SetUpScript = $setup
    }
    
    function Should([string]$name, [scriptblock]$testDefinition) {
        $context.Tests += Create-TestObject "$contextName should $name" $testDefinition
    }
    
    function TearDown([scriptblock]$teardown) {
        $context.TearDownScript = $teardown
    }
    
    &$contextDefinition
    $script:tests += $context
}
New-Alias Context New-RxContext
