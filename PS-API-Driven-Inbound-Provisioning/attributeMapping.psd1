# Copied and modified from https://github.com/AzureAD/entra-id-inbound-provisioning/blob/main/PowerShell/CSV2SCIM/Samples/AttributeMapping.psd1
@{
    externalId   = 'File Number'
    name         = @{
        familyName = 'Legal Last Name'
        givenName  = 'Legal First Name'
    }
    #active       = { $_.'WorkerStatus' -eq 'Active' }
    userName     = 'UserID'
    #displayName  = 'Legal First Name' + 'Legal Last Name'
    #nickName     = 'UserID'
    #userType     = 'WorkerType'
    title        = 'Job Title Description'
    #mail         = 'Work Contact: Work Email'
    addresses    = @(
        @{
            type          = { 'work' }
            streetAddress = 'StreetAddress'
            locality      = 'City'
            postalCode    = 'ZipCode'
            country       = 'CountryCode'
        }
    )
    #phoneNumbers = @(
    #    @{
    #        type  = { 'work' }
    #        value = 'OfficePhone'
    #    }
    #)
    "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" = @{
        #employeeID      = 'File Number'
        #costCenter     = 'CostCenter'
        #organization   = 'Company'
        #division       = 'Division'
        department      = 'DEPARTMENT'
        HireDate        = 'Hire Date'
        #manager        = @{
        #    value = 'ManagerID'
        #}
    }
}