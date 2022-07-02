class ValidIdentityException: System.Exception {
    ValidIdentityException([string] $identityException) :
        base ("This is not valid identity : $identityException") {}
}