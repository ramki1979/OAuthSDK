//
//  OAuth2.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 18/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit

public class OAuth2: OAuthClient {
    
    public override init(config: [String : String]) {
        super.init(config: config)
        
        session = NSURLSession(configuration: nil, delegate: self, delegateQueue: nil)
    }
    
    public func authenticationRequestURL(webviewParent: UIView) {
        //  Authenticate user URL
        OAuthState = .AuthenticateUser
        
        let webview = OAuthWebView(delegate:self, parent: webviewParent)
        if let navBar = webviewParent.viewWithTag(Properties.kUINavigationBar.rawValue) as? UINavigationBar {
            webviewParent.insertSubview(webview, belowSubview: navBar)
        }
        OAuthURL = makeURL(OAuthEndPoints[OAuthEndPointKeys.AuthenticateUserURL.rawValue]!)
        webview.loadRequestURL(OAuthURL)
    }
    
    public func validateAccessToken() -> OAuth2 {
    
        if keychainHelper.checkAndUpdateValueForKey(OAuthServiceName + " token") {
            //  check for AccessToken Validation..if not valid automatically refresh access_token
            OAuthState = .ValidateAccessToken
            createDataTask(OAuthEndPointKeys.ValidateAccessTokenURL.rawValue)
        }
        
        return self
    }
    
    public func createDataTask(endPointKey: String, headers: [String: String]? = nil) {
        
        OAuthURL = makeURL(OAuthEndPoints[endPointKey]!)
        
        let req = NSMutableURLRequest(URL: NSURL(string: OAuthURL)!)
        req.HTTPMethod = OAuthMethod
        
        if let headerDict = headers {
            for (key, value) in headerDict {
                req.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        println("request: \(req.URL!.host) \(req.URL!.path) \(req.URL!.query)")
        
        let dataTask = session.dataTaskWithRequest(req)
        dataTask.resume()
        
    }
    
    private func makeURL(dict:[String: String]) -> String {
        var url: String!
        var base = String()
        var start = true
        
        for (key, value) in dict {
            switch key {
            
            case "method":
                OAuthMethod = value
            
            case "url":
                url = value + "?"
            
            case "path":
                url = baseURL + value + "?"
                
            default:
                if !start {
                    if value.isEmpty {
                        base += "&\(key)=\(valueForKey(key))"
                    } else {
                        base += "&\(key)=\(value)"
                    }
                } else {
                    if value.isEmpty {
                        base += "\(key)=\(valueForKey(key))"
                    } else {
                        base += "\(key)=\(value)"
                    }
                    start = false
                }
            }
        }
        
        return url + base
    }
    
    private func valueForKey(key: String) -> String {
        
        switch key {
        case "client_id": return OAuthServiceKey
        case "client_secret": return OAuthServiceSecret
        case "access_token": return decryptToKeyChain(OAuthServiceName+" token")
        case "refresh_token": return decryptToKeyChain(OAuthServiceName+" refresh")
        case "code": return decryptToKeyChain(OAuthServiceName+" code")
            
        default: return ""
        }
    }
    
    private func processAuthenticateTokenResponse(dict: [String: AnyObject]) {
        
        var refresh_token: String!
        var access_token: String!
        for (key, val: AnyObject) in dict {
            switch key {
            case "access_token":
                access_token = val as! String
            case "refresh_token":
                refresh_token = val as! String
            default: break
            }
        }
        
        if access_token != nil {
            OAuthState = .AccessToken
            encryptToKeyChain(OAuthServiceName+" token", data: access_token, updateIfExist: true)
            
            if refresh_token != nil {
                
                keychainHelper.deleteKey(OAuthServiceName+" code", serviceId: nil)
                encryptToKeyChain(OAuthServiceName+" refresh", data: refresh_token)
                
                //  Access user profile
                createDataTask(OAuthEndPointKeys.UserProfileURL.rawValue)
            }
        }
    }
    
    private func processValidateAccessTokenResponse(dict: [String: AnyObject]) {
        
        /*
        Google Drive Response:
        Success: {
        "access_type" = offline;
        audience = "577875232180-lu50p0bfec6b1sm1qs4hgkjin7cqdll7.apps.googleusercontent.com";
        "expires_in" = 3106;
        "issued_to" = "577875232180-lu50p0bfec6b1sm1qs4hgkjin7cqdll7.apps.googleusercontent.com";
        scope = "https://www.googleapis.com/auth/drive"; }
        
        Error: {
        "error" = "invalid_token";
        "error_description" = "Invalid Value";
        }
        
        */
        
        for (key, val: AnyObject) in dict {
            switch key {
            case "error":   //  Google Drive..
                if val as! String == "invalid_token" {
                    OAuthState = .RefreshAccessToken
                    createDataTask(OAuthEndPointKeys.RefreshAccessTokenURL.rawValue)
                    return
                }
            case "error_description": break
                
            default: break
            }
        }
        
        //  token is valid...
        OAuthState = .AccessToken
        //createDataTask(OAuthEndPointKeys.UserProfileURL.rawValue)
    }
    
}

extension OAuth2: OAuthWebResponse {
    func responseURL(url: NSURL) {
        
        if let path = url.path, query = url.query {
            switch path {
            case "/google/drive": fallthrough
            case "/dropbox":
                
                if query.hasPrefix("code=") {
                    //  Got oauth_code for google drive service
                    let oauth_code = query.substringWithRange(Range(start: advance(query.startIndex, 5), end: query.endIndex))
                    encryptToKeyChain(OAuthServiceName+" code", data: oauth_code)
                    
                    // we got the code, lets authenticate the code, to get the access_token...
                    OAuthState = .AuthenticateCode
                    createDataTask(OAuthEndPointKeys.AuthenticateUserCodeForAccessTokenURL.rawValue)
                    
                } else {
                    println("responseURL: \(url)")
                }
                
            default: println("response: path:\(path) query:\(query)")
            }
            
        }
    }
}

extension OAuth2: NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    public override func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        var response: AnyObject?
        let path = task.originalRequest.URL!.host! + task.originalRequest.URL!.path!
        
        if let data = responseData[path] {
            var error: NSError?
            response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &error)
            if error != nil || response == nil {
                println("Json Error: \(error)")
                return
            }
            
            if OAuthState != .AccessToken {
                println("\nResponse (bytes: \(task.countOfBytesExpectedToReceive)): \(response)")
            } else {
                println("\nResponse (bytes: \(task.countOfBytesExpectedToReceive))")
            }
            
            //  Release the NSData response object
            responseData.removeValueForKey(path)
            
        } else {
            if let delgate = delegate {
                delgate.requestCompleteWithError(OAuthServiceName, path: path, response: responseError[path]!)
            }
            return
        }
        
        switch OAuthState {
            
        case .AuthenticateCode: fallthrough
        case .RefreshAccessToken:
            processAuthenticateTokenResponse(response! as! [String: AnyObject])
            
        case .ValidateAccessToken:
            processValidateAccessTokenResponse(response! as! [String: AnyObject])
            
        case .RevokeAccessToken: break
            
        case .AccessToken:
            if let delgate = delegate {
                delgate.requestComplete(OAuthServiceName, path: path, response: response!)
            }
            
        default: break
            
        }
    }
    
}