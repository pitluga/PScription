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
        
        foreach ($failedTest in $this.Failures) {
            Write-Host -Fore Red "FAILED:" $failedTest.name
            Write-Host -Fore Red "`t" $failedTest.exception 
        }
        
        foreach ($erroredTest in $this.Errors) {
            Write-Host -Fore Magenta "ERRORS:" $erroredTest.name
            Write-Host -Fore Magenta "`t" $erroredTest.exception
             
        }
    }
    return $aggregator
}