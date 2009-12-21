$script:tests = @()

Add-Type @"
using System;
namespace PScription 
{
    public class AssertionFailedException : Exception 
    { 
        public AssertionFailedException (string msg) : base(msg) { } 
    }
}
"@

function Assert-True([boolean]$actual, [string]$message) {
    if (-not $actual) {
        throw (New-Object AssertionFailedException -arg $message)
    }
}

function Create-ResultAggregator {
    $aggregator = New-Object PSObject
    $aggregator | Add-Member -MemberType NoteProperty -Name SuccessCount -Value 0
    $aggregator | Add-Member -MemberType NoteProperty -Name ErrorCount -Value 0
    $aggregator | Add-Member -MemberType NoteProperty -Name Errors -Value @()
    $aggregator | Add-Member -MemberType NoteProperty -Name FailureCount -Value 0
    $aggregator | Add-Member -MemberType NoteProperty -Name Failures -Value @()
    $aggregator | Add-Member -MemberType ScriptMethod -Name ReportError -Value {
        param($name, $exception)
        $this.Errors += @{ name=$name; exception=$exception }
        $this.ErrorCount += 1
        Write-Host "E" -NoNewLine -Fore Magenta
    }
    $aggregator | Add-Member -MemberType ScriptMethod -Name ReportFailure -Value {
        param($name, $exception)
        $this.Failures += @{ name=$name; exception=$exception }
        $this.FailureCount += 1
        Write-Host "F" -NoNewLine -Fore Red
    }
    $aggregator | Add-Member -MemberType ScriptMethod -Name ReportSuccess -Value {
        param($name)
        $this.SuccessCount += 1
        Write-Host "." -NoNewLine -Fore Green
    }
    $aggregator | Add-Member -MemberType ScriptMethod -Name Completed -Value {
        Write-Host ""
        Write-Host "Total Tests:" ($this.SuccessCount + $this.ErrorCount + $this.FailureCount) "Failed:" $this.FailureCount " Errors:" $this.ErrorCount
        $this.Failures | % { Write-Host "FAILED:" $_.name -Fore Red ; Write-Host "`t" $_.exception -Fore Red }
        $this.Errors | % { Write-Host "ERRORS:" $_.name -Fore Magenta ; Write-Host "`t" $_.exception -Fore Magenta }
    }
    return $aggregator
}

function Create-Test([string]$name, [scriptblock]$testDefinition) {
    $test = New-Object PSObject
    $test | Add-Member -MemberType NoteProperty -Name Name -Value $name
    $test | Add-Member -MemberType NoteProperty -Name TestScript -Value $testDefinition
    return $test
}

function Create-Context([string]$contextName) {
    $context = New-Object PSObject
    $context | Add-Member -MemberType NoteProperty -Name Name -Value $contextName
    $context | Add-Member -MemberType NoteProperty -Name SetUpScript -Value {}
    $context | Add-Member -MemberType NoteProperty -Name TearDownScript -Value {}
    $context | Add-Member -MemberType NoteProperty -Name Tests -Value @()
    $context | Add-Member -MemberType ScriptMethod -Name Execute -Value { 
        param($aggregator)
        $this.Tests | % {
            $currentTest = $_
            try {
                &$this.SetUpScript
                &$currentTest.TestScript
                &$this.TearDownScript
                $aggregator.ReportSuccess($this.Name)
            }
            catch [AssertionFailedException] {
                $aggregator.ReportFailure($currentTest.Name, $_)
            }
            catch {
                $aggregator.ReportError($currentTest.Name, $_)
            }
        } 
    }
    return $context
}

function Test([string]$name, [scriptblock]$testDefinition) {
    $test = Create-Test $name $testDefinition
    $test | Add-Member -MemberType ScriptMethod -Name Execute -Value { 
        param($aggregator)
        try {
            &$this.TestScript
            $aggregator.ReportSuccess($this.Name)
        }
        catch [AssertionFailedException] {
            $aggregator.ReportFailure($this.Name, $_)
        }
        catch {
            $aggregator.ReportError($this.Name, $_)
        }
    }
    $script:tests += $test
}

function Context([string]$contextName, [scriptblock]$contextDefinition) {
    $context = Create-Context $contextName
    
    function SetUp([scriptblock]$setup) {
        $context.SetUpScript = $setup
    }
    
    function Test([string]$name, [scriptblock]$testDefinition) {
        $context.Tests += Create-Test "$contextName Test $name" $testDefinition
    }
    
    function TearDown([scriptblock]$teardown) {
        $context.TearDownScript = $teardown
    }
    
    &$contextDefinition
    $script:tests += $context
}

Context "Given something interesting" {

    SetUp { write-host "overridden" }

    Test "That something happens" {
        write-host "testing something"
    }
    
    Test "Should Fail" {
        Assert-True $false "a good error message"
    }
    
}


Test "should also fail" {
    Assert-True $false "failed where it should!"
}

$tst = {Assert-True $false "msg"}


try {
 &$tst
}
catch [AssertionFailedException] {
write-host caught first
}
catch [PScription.AssertionFailedException] {
write-host caught explicit
}
catch {
write-host caught fallback
}

Test "without a context" { throw "yikes" }
$aggregator = Create-ResultAggregator
$script:tests | % { $_.Execute($aggregator) }
$aggregator.Completed()