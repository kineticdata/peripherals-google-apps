# Google Apps API V1
Used for requests to the Google Cloud Apps REST API Client

## Info Values
**service_account**: An account used to interact with the api.  Instruction on creating a [service account](https://developers.google.com/identity/protocols/oauth2/service-account#creatinganaccount)

**private_key**: A key obtained from google cloud platform console. The final step of the service account creation instructions above walks through creating a key. **Important note below**

**enable_debug_logging**: Yes or No. Controls logging behavior. 

## Parameters
**Error Handling**
  Select between returning an error message, or raising an exception.

**Method**
  HTTP Method to use for the Kinetic Core API call being made.
  Options are:
  - GET
  - POST
  - PUT
  - PATCH
  - DELETE

**Scope**
  Scope limits access to the users account.  Google's list of [scopes](https://developers.google.com/identity/protocols/oauth2/scopes). **Note** that the scope used must be appropriate for desired resource that will be requested using the URL handler parameter.

**User**
  The email of the user that the service account will act on.  The [user must have access](https://support.google.com/a/answer/7519580?hl=en) to the assets that are being retrieve or written.  The service account must have [domain-wide authority](https://developers.google.com/identity/protocols/oauth2/service-account#delegatingauthority).

**URL**
    A fully qualified url is required by the handler.  A list of [google app](https://developers.google.com/apis-explorer) API endpoint. 

**Body**
  The body content (JSON) that will be sent for POST, PUT, and PATCH requests.

### Example Use
  Get drive files from foo.bar@acme.com
  ``` javascript
    'method' => 'Get',
    'scope' => 'https://www.googleapis.com/auth/drive',
    'user' => 'foo.bar@acme.com',
    'url' => 'https://www.googleapis.com/drive/v3/files',
  ```

  Get a list of groups for the acme.com domain
  ``` javascript
    'method' => 'Get',
    'scope' => 'https://www.googleapis.com/auth/admin.directory.group',
    'user' => 'foo.bar@acme.com',
    'url' => 'https://admin.googleapis.com/admin/directory/v1/groups?domain=acme.com',
  ```

## Results
**Response Body**
  The returned value from the Rest Call (JSON format)

## Notes
* The first step to use this handler is to create a [new project](https://support.google.com/googleapi/answer/6251787?hl=en) or select an existing one.  Then a [service account](https://developers.google.com/admin-sdk/directory/v1/guides/delegation#create_the_service_account_and_credentials) will need to be added to the project.
* Before the project can interact with a google app it must be [enabled](https://support.google.com/googleapi/answer/6158841?hl=en).
* Creating a project, Creating a service account, Adding keys to a service account and enabling apis for the project can all be done through the [google developers console](https://analytify.io/google-developers-console/#:~:text=Google%20Developers%20Console%20is%20a,Developers%20Console%20with%20your%20Gmail.).
* The handler requires that an impersonated users be provided for the **Service Account** to make calls on behalf of.  The impersonated user provided will need access to the assets that are being requested.  Review the [Roles and Privileges](https://support.google.com/a/answer/7519580?hl=en) for the user to make sure they can access the asset.
* When the key is created for the service account a json file will be downloaded to your machine.  Copy the private_key from the file. 
  * An example input for the private_key info value: -----BEGIN PRIVATE KEY-----\nMIIEvgIBA...PH4\nrqH7SSPuSLIaiPJDgGfIeF5M\n-----END PRIVATE KEY-----\n
  * Make sure to leave the header and footer and all new lines in place.
* global domain endpoints require `?domain=<your domain>.com` be added to the parameters of the request.  This is done in the **URL** handler parameter
