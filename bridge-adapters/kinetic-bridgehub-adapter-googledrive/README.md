# Kinetic Bridgehub Adapter Googledrive
This adapter is used to make bridge calls to the google drive api endpoints.

# Google Drive Bridge Information
---
## Configuration Values
| Name                      | Description |
| :------------------------ | :------------------------- |
| Service Account Email     | an account that belongs to your application instead of to an individual end user |
| Authorization Type        | Select __P12 File__ or __Private Key__ |
| Private Key               | Instructions for getting private key in notes below |
| P12 File Location         | The path to the P12 File |
| Impersonated User Email   | The email of the user that the request will be impersonating |
| Google Apps Expiration Script Url | ??? |

### Example Configuration
| Name                      | Value |
| :------------------------ | :------------------------- |
| Service Account Email     | acme-integrator@service-account-test-55555.iam.gserviceaccount.com |
| Authorization Type        | Private Key |
| Private Key               | **Private Key Example Below** |
| P12 File Location         | /path/to/file |
| Impersonated User Email   | joe.foo@acme.com |

## Supported Structures
| Name                      | Description |
| :------------------------ | :------------------------- |
| Files                     | Search for a file |
| Folders                   | Search for a folder |

## Fields
Fields that will be returned with the record.  If no fields are provided then all fields will be
returned.

## Qualification (Query)
ex: title contains 'joe'.  Visit [Google Drive API v2](https://developers.google.com/drive/api/v2/search-files) for additional query options.

### Notes
* Setting up a Google API Project is required.  Visit [Google Play Developer API](https://developers.google.com/android-publisher/getting_started) doc for information on how to set up project.
* A [Service account](https://developers.google.com/android-publisher/getting_started#using_a_service_account) is required.
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
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCZ7VJdnuZR2w5P
...
TP62zYhLwBIKTVg9+3VQQmc1Lw==
-----END PRIVATE KEY-----