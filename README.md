# OAuthSDK 

The OAuthSDK [v 0.1] is an iOS > (8.0) Framework that supports both OAuth 1.0a and 2.0. The goals of this framework are below:

1. Any new service should be autoconfigurable, through JSON file.
2. Supports libsodium for Encrypting/Decrypting of Data
3. Realm database support for storing data.
4. Create, Public OpenOAuthStore service, to store OAuth App Client secrets. [Open to All], 
if there is one already available kindly let me know.

Currently, the library works for both OAuth 1 & 2, but need to clean few things in the framework.

oauth_tokens & access_tokens are stored in Keychain now, but will be move to Realm database using libsodium.

# Framework Status:
This is an Intial commit, The main goals are yet to be kick start!!

### App ids & secrets provided here doesn't work, they are just for illustration.
## Creating OAuth1 Service
```swift

class TwitterService: OAuth1 {
    
    init(service: String) {
        //  In future config is done through local or remote JSON file, 
        //  server supports only https...
        //  All credential should be saved to keychain or realm database using libsodium.
        
        let config = [
            "service":service,
            "base_url":"https://api.twitter.com/1.1",
            "consumer_key":"2cyqKxhrMcV8YJSH8Ed6A",
            "consumer_secret":"BcP8Fdcn6FWpWCPwC3Lk4frZ58OE6Lh0CE60cjRoEMw"]
        
        super.init(config: config)
        delegate = self
        
        //  Add Default API Endpoints here...
        let requestToken = ["method":"POST", "url":"https://api.twitter.com/oauth/request_token", "format":"&=", "oauth_callback":"https://127.0.0.1:9000/oauth1/twitter/"]
        let authenticateUser = ["url":"https://api.twitter.com/oauth/authorize"]
        let authenticateCode = ["method":"POST","url":"https://api.twitter.com/oauth/access_token", "format":"&="]
        
        addEndPoint(OAuthEndPointKeys.RequestTokenURL.rawValue, value: requestToken)
        addEndPoint(OAuthEndPointKeys.AuthenticateUserURL.rawValue, value: authenticateUser)
        addEndPoint(OAuthEndPointKeys.AuthenticateCodeURL.rawValue, value: authenticateCode)

    }
}

```

## Starting the OAuth 1 service, for user authentication & authorization.

```swift

  //  Create instance of the service with service name as title or anything..
  twitterService = TwitterService(service: title)
  googleDriveClient = GoogleDriveCloud(service: "Google Drive")
  
  // call the "authenticationRequestURL" method to start the OAuth flow..
  // OAuthSDK embedded UIWebView will add as a subview to the input view. 
  googleDriveClient.authenticationRequestURL(self.view)
  twitterService.authenticationRequestURL(self.view)


```

## Creating OAuth2 Service

```swift

class GoogleDriveCloud: OAuth2 {
    
    init(service: String) {
        //  In future config is done through local or remote JSON file, 
        //  server supports only https...
        //  All credential should be saved to keychain or realm database using libsodium.
        
        let config = [
            "service":service,
            "base_url":"https://www.googleapis.com/drive/v2",
            "client_id":"577875232180-lu50p0bfec6b1sm1qs4hgkjin7cqdll7.apps.googleusercontent.com",
            "client_secret":"W0ntPfx269Zts3XAq50jL857"]
        
        super.init(config: config)
        delegate = self
        
        //  Add Default API Endpoints here...
        let authenticateUser = ["url":"https://accounts.google.com/o/oauth2/auth", "scope": "https://www.googleapis.com/auth/drive", "redirect_uri": "http://localhost/google/drive", "response_type": "code", "client_id":""]
        let authenticateCode = ["method":"POST","url":"https://www.googleapis.com/oauth2/v3/token","code":"","client_id":"","client_secret":"","redirect_uri":"http://localhost/google/drive","grant_type":"authorization_code"]
        let refreshToken = ["method":"POST","url":"https://www.googleapis.com/oauth2/v3/token","client_id":"","client_secret":"","refresh_token":"","grant_type":"refresh_token"]
        let validateToken = ["method":"GET","url":"https://www.googleapis.com/oauth2/v1/tokeninfo","access_token":""]
        let profile = ["method":"GET", "path":"/about", "access_token":""]
        
        addEndPoint(OAuthEndPointKeys.AuthenticateUserURL.rawValue, value: authenticateUser)
        addEndPoint(OAuthEndPointKeys.AuthenticateCodeURL.rawValue, value: authenticateCode)
        addEndPoint(OAuthEndPointKeys.RefreshAccessTokenURL.rawValue, value: refreshToken)
        addEndPoint(OAuthEndPointKeys.ValidateAccessTokenURL.rawValue, value: validateToken)
        addEndPoint(OAuthEndPointKeys.UserAccountInfoURL.rawValue, value: profile)
    }
}

```

## Starting the OAuth 2 service, for user authentication & authorization.

```swift

  //  Create instance of the service with service name as title or anything..
  googleDriveClient = GoogleDriveCloud(service: "Google Drive")
  
  // call the "authenticationRequestURL" method to start the OAuth flow..
  // OAuthSDK embedded UIWebView will add as a subview to the input view. 
  googleDriveClient.authenticationRequestURL(self.view)

```

### OAuthSDK communicate API Response to its "OAuthRequestResponse" protocol
Either Individual service or the MainViewController can confirm to this protocol to get the responses.

#### These are not properly defiend yet.

```swift

  /*  serviceName:  Configured service title,
  //  API Endpoint: The Requested API Path
  //  response:     The JSON Response for the requested API
  */
  func requestComplete(serviceName: String, path: String, response: AnyObject) {
        
  }
    
  func requestCompleteWithError(serviceName: String, path: String, response: String) {
        
  }
    
  func requestFailedWithError(serviceName: String, path: String, error: String) {
        
  }

```