//
//  TwitterService.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 20/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import Foundation
import OAuthSDK

class TwitterService: OAuth1 {
    //  Add json config to make this easier...
    init(service: String) {
        //  client_secret -> should be get from the server
        //  server supports only https...
        //  once received, it has to be stored into the keychain
        //  client secret shouldn't be stored in plaintext, its has to be encrypted
        
        let config = [
            "service":service,
            "base_url":"https://api.twitter.com/1.1",
            "consumer_key":"2cyqKxhrMcV8YJSH8Ed6A",
            "consumer_secret":"BcP8Fdcn6FWpWCPwC3Lk4frZ58OE6Lh0CE60cjRoEMw"]
        
        super.init(config: config)
        delegate = self
        
        //  Add Default API Endpoints here...
        let requestToken = ["method":"POST", "url":"https://api.twitter.com/oauth/request_token", "format":"&=", "oauth_callback":"https://127.0.0.1:9000/oauth1/twitter/"]
        let authenticateUser = ["url":"https://api.twitter.com/oauth/authorize", "oauth_token":""]
        let authenticateRequestTokenForAccessToken = ["method":"POST","url":"https://api.twitter.com/oauth/access_token", "format":"&="]
//        let refreshToken = ["method":"POST","url":"https://www.googleapis.com/oauth2/v3/token","client_id":"","client_secret":"","refresh_token":"","grant_type":"refresh_token"]
//        let validateToken = ["method":"GET","url":"https://www.googleapis.com/oauth2/v1/tokeninfo","access_token":""]
        let profile = ["method":"GET", "path":"/users/show.json", "screen_name":""]
        
        addEndPoint(OAuthEndPointKeys.RequestTokenURL.rawValue, value: requestToken)
        addEndPoint(OAuthEndPointKeys.AuthenticateUserURL.rawValue, value: authenticateUser)
        addEndPoint(OAuthEndPointKeys.AuthenticateUserCodeForAccessTokenURL.rawValue, value: authenticateRequestTokenForAccessToken)
//        addEndPoint(OAuthEndPointKeys.RefreshAccessTokenURL.rawValue, value: refreshToken)
//        addEndPoint(OAuthEndPointKeys.ValidateAccessTokenURL.rawValue, value: validateToken)
        addEndPoint(OAuthEndPointKeys.UserProfileURL.rawValue, value: profile)
        
    }
}

extension TwitterService: OAuthRequestResponse {
    func requestComplete(serviceName: String, path: String, response: AnyObject) {
        
    }
    
    func requestCompleteWithError(serviceName: String, path: String, response: String) {
        
    }
    
    func requestFailedWithError(serviceName: String, path: String, error: String) {
        
    }
}