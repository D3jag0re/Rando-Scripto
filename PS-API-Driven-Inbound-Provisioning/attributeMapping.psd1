# Copied and modified from https://github.com/AzureAD/entra-id-inbound-provisioning/blob/main/PowerShell/CSV2SCIM/Samples/AttributeMapping.psd1
# Lots of attributes are created and mapped in the portal using values from here as well (for ex, distinguished name, mail, etc.) or null defaults (company name etc.)
@{
    externalId   = 'File Number'
    name         = @{
        familyName = 'Legal Last Name'
        givenName  = 'Legal First Name'
    }
    active       = { $_.'Position Status' -eq 'Active' }
    title        = 'Job Title Description'
    addresses    = @(
        @{
            type          = { 'work' }
            streetAddress = 'StreetAddress'
            locality      = 'City'
            postalCode    = 'ZipCode'
            country       = 'CountryCode'
        }
    )

    "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User" = @{
        department      = 'DEPARTMENT'
        manager        = @{
            # The below value gets modified in the script to become the managers employeeID
            value = 'Reports To Legal First Name'
        }
    }

    "urn:ietf:params:scim:schemas:extension:identityman:1.0:User" = @{
        HireDate     = 'Hire Date'
    }
}

# Manager Reports To Legal First Name,Reports To Legal Last Name