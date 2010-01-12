Context "Within a context" {

    SetUp {
        $setThis = "in Setup"
    }

    Test "that tests run" {
        Assert-True $true "true was true, whew!"
    }

    Test "that setup should run before" {
        Assert-Equal "in Setup" $setThis
    }
    
}


Context "TearDown" {

    SetUp {
        $variable = "Value"
    }
    
    Test "has access to the setup variables" {}

    TearDown {
        Assert-Equal "Value" $variable
    }
}