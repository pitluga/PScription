function Invoke-Tests([string] $directory) {
    $testFiles = (Get-ChildItem -Path $directory -Recurse)

    $script:tests = @()
    foreach ($testFile in $testFiles) {
      . $testFile.FullName
    }
    $aggregator = Create-ResultAggregator
    foreach ($test in $script:tests) {
        $test.Execute($aggregator)
    }
    $aggregator.Completed()
}
