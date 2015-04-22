//
//  GoogleDriveCloud.swift
//  OAuthSDK Example
//
//  Created by RamaKrishna Mallireddy on 16/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import Foundation
import OAuthSDK

class GoogleDriveCloud: OAuth2 {
    //  Add json config to make this easier...
    init(service: String) {
        //  client_secret -> should be get from the server
        //  server supports only https...
        //  once received, it has to be stored into the keychain
        //  client secret shouldn't be stored in plaintext, its has to be encrypted
        
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
        
        //  can check the access token we have is valid or not!!
        // validateAccessToken()
    }

}

extension GoogleDriveCloud: OAuthRequestResponse {
    func requestComplete(serviceName: String, path: String, response: AnyObject) {
        
    }
    
    func requestCompleteWithError(serviceName: String, path: String, response: String) {
        
    }
    
    func requestFailedWithError(serviceName: String, path: String, error: String) {
        
    }
}