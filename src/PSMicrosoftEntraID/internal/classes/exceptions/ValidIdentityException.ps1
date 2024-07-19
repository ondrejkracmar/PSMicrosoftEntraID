$validateIdentityExceptionCodeCode = @'
using System;
    public class ValidIdentityException: Exception
    {
        public ValidIdentityException()
        {

        }

        public ValidIdentityException(string identityException): base(string.Format("This is not valid identity format {0}.", identityException))
        {

        }
    }
'@
Try{
    if(-not [ValidIdentityException] -as [type]){

    }
}
catch{
    Add-Type -TypeDefinition $validateIdentityExceptionCodeCode
}