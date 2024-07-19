<#class ValidateIdentityAttribute : System.Management.Automation.ValidateArgumentsAttribute {
    # this class must override the method "Validate()"
    # this method MUST USE the signature below. DO NOT change data types
    # $path represents the value assigned by the user:
    [void]Validate([object]$identityList, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        foreach ($identity in $identityList) {
            # perform whatever checks you require.

            # check whether the identity is empty:
            if ([string]::IsNullOrWhiteSpace($identity)) {
                # whenever something is wrong, throw an exception:
                Throw [System.ArgumentNullException]::new()
            }

            # check whether the path exists:
            if ((-not ($identity -match '@')) -and ( -not ($identity -match ("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")))) {
                # whenever something is wrong, throw an exception:
                Throw [Exception]::new($identity)
            }


            # if at this point no exception has been thrown, the value is ok
            # and can be assigned.
        }
    }
}#>

$ValidateUserIdentityAttributeCode= @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Text.RegularExpressions;

    public class ValidUserIdentityException: Exception
    {
        public ValidUserIdentityException()
        {

        }

        public ValidUserIdentityException(string identityException): base(string.Format("This is not valid user identity format '{0}'.", identityException))
        {

        }
    }

    public class ValidateUserIdentityAttribute : System.Management.Automation.ValidateArgumentsAttribute
    {
        protected override void Validate(object identityList, EngineIntrinsics engineEntrinsics)
        {
            if(identityList.GetType().IsArray) {
                string[] strIdentityList = (string[])identityList;
                foreach (string identity in strIdentityList)
                {
                    if (String.IsNullOrWhiteSpace(identity.ToString()))
                    {
                        throw new ArgumentNullException();
                    }

                    var regexId = new Regex(@"^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$");
                    var regexUPN = new Regex(@"@");

                    if (!regexId.IsMatch(identity) && !regexUPN.IsMatch(identity))
                    {
                        throw new ValidUserIdentityException(identity);
                    }
                }
            }
            else {
                string identity = (string)identityList;
                if (String.IsNullOrWhiteSpace(identity.ToString()))
                {
                    throw new ArgumentNullException();
                }

                var regexId = new Regex(@"^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$");
                var regexUUPN = new Regex(@"@");

                if (!regexId.IsMatch(identity) && !regexUUPN.IsMatch(identity))
                {
                    throw new ValidUserIdentityException(identity);
                }
            }
        }
    }
'@
# compile c# code
Try{
    if( [ValidateUserIdentityAttribute] -as [type]){

    }
}
catch{
    Add-Type -TypeDefinition $ValidateUserIdentityAttributeCode
}