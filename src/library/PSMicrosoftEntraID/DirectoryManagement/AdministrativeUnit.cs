using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.DirectoryManagement
{
    /// <summary>
    /// Represents an administrative unit in Microsoft Entra ID.
    /// Administrative units restrict permissions in a role to any portion of your organization that you define.
    /// For example, you could use administrative units to delegate the Helpdesk Administrator role to regional support specialists, 
    /// so they can manage users only in the region that they support.
    /// </summary>
    [DataContract]
    public class AdministrativeUnit
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AdministrativeUnit"/> class.
        /// </summary>
        public AdministrativeUnit()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the administrative unit.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the administrative unit was created.
        /// </summary>
        [DataMember(Name = "createdDateTime")]
        public string CreatedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the administrative unit was deleted.
        /// </summary>
        [DataMember(Name = "deletedDateTime")]
        public string DeletedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the display name of the administrative unit.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the description of the administrative unit.
        /// </summary>
        [DataMember(Name = "description")]
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the visibility of the administrative unit.
        /// Controls whether the administrative unit and its members are hidden or public.
        /// Can be HiddenMembership or Public. If not set, the default behavior is Public.
        /// </summary>
        [DataMember(Name = "visibility")]
        public string Visibility { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the management of members in this administrative unit is restricted to administrators.
        /// If true, only administrators can manage the members of this administrative unit.
        /// If false, both administrators and users can manage the members.
        /// </summary>
        [DataMember(Name = "isMemberManagementRestricted")]
        public bool? IsMemberManagementRestricted { get; set; }

        /// <summary>
        /// Gets or sets the collection of members in this administrative unit.
        /// This property is read-only and can include users, groups, and devices.
        /// </summary>
        [DataMember(Name = "members")]
        public Member[] Members { get; set; }

        /// <summary>
        /// Gets or sets the collection of scoped role members in this administrative unit.
        /// This property is read-only and represents users or groups with administrative roles scoped to this unit.
        /// </summary>
        [DataMember(Name = "scopedRoleMembers")]
        public ScopedRoleMember[] ScopedRoleMembers { get; set; }

        /// <summary>
        /// Gets or sets additional extensions for the administrative unit.
        /// </summary>
        [DataMember(Name = "extensions")]
        public Extension[] Extensions { get; set; }
    }
}