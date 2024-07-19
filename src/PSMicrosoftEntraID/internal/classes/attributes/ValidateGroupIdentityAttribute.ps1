$ValidateGroupIdentityAttributeCode= @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Text.RegularExpressions;

    public class ValidGroupIdentityException: Exception
    {
        public ValidGroupIdentityException()
        {

        }

        public ValidGroupIdentityException(string identityException): base(string.Format("This is not valid group identity format '{0}'.", identityException))
        {

        }
    }

    public class ValidateGroupIdentityAttribute : System.Management.Automation.ValidateArgumentsAttribute
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
                    var regexMailNickName = new Regex("[]@();:<>, \"[]");

                    if (!regexId.IsMatch(identity) && regexMailNickName.IsMatch(identity))
                    {
                        throw new ValidGroupIdentityException(identity);
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
                var regexMailNickName = new Regex("[]@();:<>, \"[]");

                if (!regexId.IsMatch(identity) && regexMailNickName.IsMatch(identity))
                {
                    throw new ValidGroupIdentityException(identity);
                }
            }
        }
    }
'@
# compile c# code
Try{
    if( [ValidateGroupIdentityAttribute] -as [type]){

    }
}
catch{
    Add-Type -TypeDefinition $ValidateGroupIdentityAttributeCode
}