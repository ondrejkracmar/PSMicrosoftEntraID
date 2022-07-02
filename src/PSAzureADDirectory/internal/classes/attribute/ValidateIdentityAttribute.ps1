class ValidateIdentityAttribute : System.Management.Automation.ValidateArgumentsAttribute
{
    # this class must override the method "Validate()"
    # this method MUST USE the signature below. DO NOT change data types
    # $path represents the value assigned by the user:
    [void]Validate([object]$identityList, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
    {
        foreach ($identity in $identityList)
        {
            # perform whatever checks you require.
        
            # check whether the identity is empty:
            if([string]::IsNullOrWhiteSpace($identity))
            {
                # whenever something is wrong, throw an exception:
                Throw [System.ArgumentNullException]::new()
            }
        
            # check whether the path exists:
            if((-not ($identity -match '@')) -and ( -not ($identity -match ("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"))))
            {
                # whenever something is wrong, throw an exception:
                Throw [ValidIdentityException]::new($identity)
            }
        
        
            # if at this point no exception has been thrown, the value is ok
            # and can be assigned.    
        }
    }
}