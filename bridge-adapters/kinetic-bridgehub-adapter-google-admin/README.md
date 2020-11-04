# Kinetic Bridgehub Adapter Google Admin
This adapter is used to make bridge calls to the google admin api endpoints.

# Google Admin Bridge Information
---
## Configuration Values
| Name                      | Description |
| :------------------------ | :------------------------- |
| Service Account Email     | an account that belongs to your application instead of to an individual end user |
| Authorization Type        | Select __P12 File__ or __Private Key__ |
| Private Key               | Instructions for getting the private key are below |
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
Fields that will be returned with the record.  If no fields are provided then no fields will be returned. For a list of valid fields visit [Google Admin API](https://developers.google.com/admin-sdk/directory/v1/guides/search-users#fields).

## Qualification (Query)
ex: name:'joe'.  Visit [Google Admin API v1](https://developers.google.com/admin-sdk/directory/v1/guides/search-users#examples) for additional query options.

## Google project setup
Setting up a Google API Project is required. To complete all of the google project setup steps the user should have google super admin privileges.  The ability to access the google developer console is required to crate the project.  Adding domain wide delegation to the service account requires super users privileges.

### Create project
  1. Go to the Google API Console at https://console.developers.google.com/project. 
  2. Click Create project 
     * Enter a name
     * Select an organization (if applicable)
     * Click Create
  3. Once the project is created it can be selected.  (move to step two under add a service account)
### Add Service Account to project 
A [Service account](https://developers.google.com/admin-sdk/directory/v1/guides/delegation#create_the_service_account_and_credentials) is required for the adapter configuration.
  1. Select the project from the Google API Console.
     * There are several way to do this, one option is to select the project from the dropdown next to the GoogleAPIs icon.
  2. Click on **Credentials** the left side to bring up the credentials page.
     * There is a menu that opens if you click on the GoogleAPIs icon in the header.
  3. Click **+ CREATE CREDENTIALS** button near the top of the screen.
  4. Choose **Service Account** from the dropdown.
     1. Give the account a name.
         * An email for the **Service Account** is generated.  This will a configuration value for the **Plugin** later.
     2. Add a description (optional)
     3. Click **CREATE**.
     4.  Click **DONE**.
  * Once the **DONE** button is clicked you will be redirect to the **Service Account** table.  Continue to Create access key
### Create access key
The adapter has two methods for adding access credentials; **P12 file** or **Private key**. The **Private Key** is generated from the **P12 file**
  1. From the **Service Account** table select the service account to add a key to.
     * The **Service Account** table can be found on the credentials page.
  2. On the __Grant users access to this service account__ screen 
     * Scroll down to the **Keys** key section. 
     * Click **ADD KEY**.
  3. Choose **Create new key** from the options.
  4. Choose **P12** as the key type and click **CREATE**.
     * This will download a **P12 file** to your local machine.  Store the __Private key password__ in a secure location.
     * To configure the bridge adapter to use the **P12 file**, access to the file system that the __Agent__ is running on is required.
     * If you don't have access to the __Agent's__ file system the the **P12 file** needs to be converted to a **Private Key**.
#### Extract **Private Key** from  **P12 file**
  1. In the terminal run `openssl pkcs12 -info -in INFILE.p12 -nodes -nocerts` command.
     * Visit [Private Key from the P12 file](https://www.ssl.com/how-to/export-certificates-private-key-from-pkcs12-file-with-openssl/) for more information.
  2. Copy the **Private Key** to config (Do not edit)
     * The **Private Key** will be used in the configuration of the adapter.
     * Below is an example of a successful extraction of the **Private Key**.  
### Enable API access for project
  1. Go to the Google API console.
  2. Click on **Dashboard** the left side menu.
  3. Click **+ ENABLE APIS AND SERVICES** button near the top of the screen.
     * This will take you to the API Library page.
  4. Search for **ADMIN SDK** and select it form the list.
  5. Click on the **ENABLE** button.
### Give Service Account **Domain-Wide Delegation**
Set [Delegate domain-wide](https://developers.google.com/admin-sdk/directory/v1/guides/delegation#delegate_domain-wide_authority_to_your_service_account) authority to your service account.
  1. Select the Service Account from the table to get to the __Grant users access to this service account__ screen.
     * The table can be found on the **Credentials** page in the **Google API Console**.
  2. Copy the Unique ID. __This is used in step 7__.
  3. Go to __G Suite__ domain's __Admin Console__ at admin.google.com
  4. Go to **(hamburger) Main menu > Security > API controls**.
  5. In the **Domain wide delegation** pane, select **Manage Domain Wide Delegation**.
  6. Click **Add new**.
  7. In the **Client ID** field, enter the client ID copied from step two.
  8. In the OAuth Scopes field add `https://www.googleapis.com/auth/admin.directory.user`.
     * more info on [OAuth Scopes](https://developers.google.com/identity/protocols/oauth2/scopes).

### Notes
* The adapter is not currently setup to use **JSON** keys.
* It is important to keep the key's tags.
Private Key Example:
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkw8gSlAgEAAoIBAQCZ7VJdnuZR2w5P
...
TP62zYhLwBIKTVg9+3VQQmc1Lw==
-----END PRIVATE KEY-----