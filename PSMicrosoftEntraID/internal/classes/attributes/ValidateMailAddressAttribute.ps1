$validateMailAddressAttributeCode = @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Text.RegularExpressions;

    public class ValidMailAddressException: Exception
    {
        public ValidMailAddressException()
        {

        }

        public ValidMailAddressException(string mailAddressException): base(string.Format("This is not valid mail address format '{0}'.", mailAddressException))
        {

        }
    }

    public class ValidateMailAddressAttribute : System.Management.Automation.ValidateArgumentsAttribute
    {
        protected override void Validate(object mailAddressList, EngineIntrinsics engineEntrinsics)
        {
            if(mailAddressList.GetType().IsArray) {
                string[] strMailAddressList = (string[])mailAddressList;
                foreach (string mailAddress in strMailAddressList)
                {
                    if (String.IsNullOrWhiteSpace(mailAddress.ToString()))
                    {
                        throw new ArgumentNullException();
                    }

                    var regexMailAddress = new Regex(@"@");

                    if (!regexMailAddress.IsMatch(mailAddress))
                    {
                        throw new ValidMailAddressException(mailAddress);
                    }
                }
            }
            else {
                string mailAddress = (string)mailAddressList;
                if (String.IsNullOrWhiteSpace(mailAddress.ToString()))
                {
                    throw new ArgumentNullException();
                }

                var regexMailAddress = new Regex(@"@");

                if (!regexMailAddress.IsMatch(mailAddress))
                {
                    throw new ValidMailAddressException(mailAddress);
                }
            }
        }
    }
'@
# compile c# code
Try {
    if ( [ValidateMailAddressAttribute] -as [type]) {

    }
}
catch {
    Add-Type -TypeDefinition $validateMailAddressAttributeCode
}