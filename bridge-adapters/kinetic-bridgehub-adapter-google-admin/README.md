# Kinetic Bridgehub Adapter Google Admin
This adapter is used to make bridge calls to the google admin api endpoints.

# Google Admin Bridge Information
---
## Configuration Values
| Name                      | Description |
| :------------------------ | :------------------------- |
| Service Account Email     | an account that belongs to your application instead of to an individual end user |
| Authorization Type        | Select __P12 File__ or __Private Key__ |
| Private Key               | Instructions for getting private key in notes below |
| P12 File Location         | The path to the P12 File |
| Impersonated User Email   | The email of the user that the request will be impersonating |
| Domain                    | The Google domain associated to the service account |

### Example Configuration
| Name                      | Value |
| :------------------------ | :------------------------- |
| Service Account Email     | acme-integrator@service-account-test-55555.iam.gserviceaccount.com |
| Authorization Type        | Private Key |
| Private Key               | **Private Key Example Below** |
| P12 File Location         | /path/to/file |
| Impersonated User Email   | joe.foo@acme.com |
| Domain                    | acme.com |

## Supported Structures
| Name                      | Description |
| :------------------------ | :------------------------- |
| Users                     | Search for a users |

## Fields
Fields that will be returned with the record.  If no fields are provided then no fields will be returned.

## Qualification (Query)
ex: name:'joe'.  Visit [Google Drive API v2](https://developers.google.com/admin-sdk/directory/v1/guides/search-users#examples) for additional query options.

### Notes
* Setting up a Google API Project is required.  Visit [Google Play Developer API](https://developers.google.com/android-publisher/getting_started) doc for information on how to set up project.
* A [Service account](https://developers.google.com/android-publisher/getting_started#using_a_service_account) is required.
* Set [Delegate domain-wide](https://developers.google.com/admin-sdk/directory/v1/guides/delegation#delegate_domain-wide_authority_to_your_service_account) authority to your service account.
    * Add https://www.googleapis.com/auth/admin.directory.user [OAuth Scope](https://developers.google.com/identity/protocols/oauth2/scopes) to the service account.
* At the google developer console
    1. Select the project from the dropdown
    2. Click **Credentials** from the left hand menu
    3. Click __+ CREATE CREDENTIALS__ button at the top of the screen
        * Select Service account
        * Fill in details
    4. Select the service account from the table
    5. Add new key
        * Create key
    6. Choose P12 and click __CREATE__
    * Make note of the Private key password.
* For Private Key Authorization. 
    * Get the [Private Key from the P12 file](https://www.ssl.com/how-to/export-certificates-private-key-from-pkcs12-file-with-openssl/)
    * Copy the Private Key to config (Do not edit)

Private Key Example:
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkw8gSlAgEAAoIBAQCZ7VJdnuZR2w5P
...
TP62zYhLwBIKTVg9+3VQQmc1Lw==
-----END PRIVATE KEY-----