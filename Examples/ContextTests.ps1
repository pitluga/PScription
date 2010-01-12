Context "context" {

    SetUp {
        $setThis = "in Setup"
    }

    Should "run tests" {
        Assert-True $true "true was true, whew!"
    }

    Should "run setup before the tests" {
        Assert-Equal "in Setup" $setThis
    }
    
}


Context "TearDown" {

    SetUp {
        $variable = "Value"
    }
    
    Should "run teardown after the test" {}

    TearDown {
        Assert-Equal "Value" $variable
    }
}