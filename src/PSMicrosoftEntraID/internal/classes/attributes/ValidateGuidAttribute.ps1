$ValidateGuidAttributeCode = @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Text.RegularExpressions;

    public class ValidGuidException : Exception
    {
        public ValidGuidException()
        {

        }

        public ValidGuidException(string guidException) : base(string.Format("This is not valid guid format '{0}'.", guidException))
        {

        }
    }

    public class ValidateGuidAttribute : System.Management.Automation.ValidateArgumentsAttribute
    {
        protected override void Validate(object strGuid, EngineIntrinsics engineEntrinsics)
        {
            if(strGuid.GetType().IsArray) {
                string[] strGuidList = (string[])strGuid;
                foreach (string itemGuidList in strGuidList)
                {
                    if(String.IsNullOrWhiteSpace(itemGuidList.ToString())) {
                        throw new ArgumentNullException();
                    }

                    var regexGuid = new Regex(@"^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$");

                    if(!regexGuid.IsMatch(itemGuidList.ToString())) {
                        throw new ValidGuidException(itemGuidList.ToString());
                    }
                }
            }
            else{
                string itemGuid = (string)strGuid;
                if(String.IsNullOrWhiteSpace(itemGuid.ToString())) {
                    throw new ArgumentNullException();
                }

                var regexGuid = new Regex(@"^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$");

                if(!regexGuid.IsMatch(itemGuid.ToString())) {
                    throw new ValidGuidException(itemGuid.ToString());
                }

            }
        }
    }
'@
# compile c# code
Try {
    if ( [ValidateGuidAttribute] -as [type]) {

    }
}
catch {
    Add-Type -TypeDefinition $ValidateGuidAttributeCode
}