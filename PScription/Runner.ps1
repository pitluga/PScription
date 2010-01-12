function Invoke-Tests([string] $directory) {
    $testFiles = (Get-ChildItem -Path $directory -Recurse)

    $script:tests = @()
    foreach ( $testFile in $testFiles ) {
      . $testFile.FullName
    }
    $aggregator = Create-ResultAggregator
    $script:tests | % { $_.Execute($aggregator) }
    $aggregator.Completed()
}
