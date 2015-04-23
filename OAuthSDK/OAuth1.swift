//
//  OAuth1.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 18/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit
import Sodium

//  For media uploads, queryparameters will be sent in POST body...
public enum ParametersInclusionType {
    case OAuthHeaders   //  All parameters will be sent as Authorization Header
    case QueryString    //  All parameters will be sent as QueryString
    case OAuthMix       //  OAuth parameters will be sent as Authorization Header, and other
                        //  parameters will be sent as QueryString, This is the default
}


public class OAuth1: OAuthClient {
    var OAuthHeader = String()
    var OAuthResponseParseFormat: String!
    let OAuth1EncodingSet:NSCharacterSet
    weak var webView: OAuthWebView?
    public var OAuthHeaderType: ParametersInclusionType = .OAuthMix
    
    public override init(config: [String : String]) {
        
        var encoding = NSMutableCharacterSet.decimalDigitCharacterSet()
        encoding.formUnionWithCharacterSet(NSMutableCharacterSet.uppercaseLetterCharacterSet())
        encoding.formUnionWithCharacterSet(NSMutableCharacterSet.lowercaseLetterCharacterSet())
        encoding.addCharactersInString("-._~")
        
        OAuth1EncodingSet = encoding
        
        super.init(config: config)
        
        if keychainHelper.checkAndUpdateValueForKey(OAuthServiceName + "oauth_token") {
            OAuthState = .AccessToken
        }
        
        session = NSURLSession(configuration: nil, delegate: self, delegateQueue: nil)
    }
    
    public func authenticationRequestURL(webviewParent: UIView) {
        OAuthState = OAuthClientState.RequestToken
        createDataTask(OAuthEndPointKeys.RequestTokenURL.rawValue)
        
        let webview = OAuthWebView(delegate:self, parent: webviewParent)
        if let navBar = webviewParent.viewWithTag(Properties.kUINavigationBar.rawValue) as? UINavigationBar {
            webviewParent.insertSubview(webview, belowSubview: navBar)
        }
        webView = webview
    }
    
    private func authenticationRequestURL() {
        //  Authenticate user URL
        OAuthState = .AuthenticateUser
        let params = resolveMissingUrlParams(OAuthEndPointKeys.AuthenticateUserURL.rawValue)
        
        var queryString = String()
        
        for (key, value) in params {
            if queryString.isEmpty {
                queryString += "?"
            } else {
                queryString += "&"
            }
            queryString += "\(key)=\(value)"
        }
        
        OAuthURL = params["url"]! + queryString
        
        webView!.loadRequestURL(OAuthURL)
    }
    
    private func resolveMissingUrlParams(endPointKey: String) -> [String: String] {
        
        var params = OAuthEndPoints[endPointKey]!
        
        if OAuthState == .AuthenticateUser && params["oauth_token"] != nil {
            params["oauth_token"] = valueForKey("request_oauth_token")
        }
        
        for (key, value) in params {
            if value.isEmpty {
                params[key] = valueForKey(key)
            }
        }
        
        return params
        
    }
    
    public func createDataTask(endPointKey: String, headers: [String: String]? = nil, fileUpload: Bool = false) {
        
        let params = resolveMissingUrlParams(endPointKey)
        
        let queryString = makeURLAndReturnQueryString(params)
        
        if let val = params["path"] {
            OAuthURL = "\(baseURL)\(val)"
        } else if let val = params["url"] {
            OAuthURL = "\(val)"
        }
        
        //  Adding query string, has few cases to consider,
        /*  */
        if fileUpload {
            
        } else {
            OAuthURL += queryString.isEmpty ? "" : "?\(queryString)"
        }
        
        let req = NSMutableURLRequest(URL: NSURL(string: OAuthURL)!)
        req.HTTPMethod = OAuthMethod
        req.setValue(OAuthHeader, forHTTPHeaderField: "Authorization")
        
        if let headerDict = headers {
            for (key, value) in headerDict {
                req.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        println("request: \(req.URL!.host) \(req.URL!.path) \(req.URL!.query)")
        
        let dataTask = session.dataTaskWithRequest(req)
        dataTask.resume()
        
    }
    
    //  oauth_nonce, oauth_timestamp, oauth_consumer_key, oauth_signature_method, oauth_version
    //  oauth_callback, oauth_signature, oauth_token
    
    private func makeURLAndReturnQueryString(var params:[String: String]) -> String {
        var queryString = String()
        
        //  OAuth nonce and timestamp generation
        let sodium = Sodium()!
        let randomData = sodium.randomBytes.buf(12)!
        let nonce = randomData.base64EncodedDataWithOptions(nil).toString()!
        let timeStamp = Int(NSDate().timeIntervalSince1970)
        
        params["oauth_nonce"] = nonce
        params["oauth_consumer_key"] = OAuthServiceKey
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_timestamp"] = "\(timeStamp)"
        params["oauth_version"] = "1.0"
        
        switch OAuthState {
        case .AuthenticateCode:
            params["oauth_token"] = valueForKey("request_oauth_token")
            params["oauth_verifier"] = valueForKey("oauth_verifier")
        case .AccessToken:
            params["oauth_token"] = valueForKey("oauth_token")
        default: break
        }
        
        params["oauth_signature"] = generateSignature(params)
        
        OAuthHeader.removeAll(keepCapacity: true)
        for (key, value) in params {
            
            switch key {
            case "method": break
            case "url": break
            case "path": break
            case "format": OAuthResponseParseFormat = value
            default:
                
                let encodedKey = key.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
                let encodedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
                
                switch OAuthHeaderType {
                case .OAuthHeaders:
                    
                    if OAuthHeader.isEmpty {
                        OAuthHeader += "OAuth "
                    } else {
                        OAuthHeader += ", "
                    }
                    
                    OAuthHeader += "\(encodedKey)=\"\(encodedValue)\""
                    
                case .QueryString:
                    
                    if queryString.isEmpty == false {
                        queryString += "&"
                    }
                    queryString += "\(encodedKey)=\(encodedValue)"
                    
                case .OAuthMix:
                    
                    if key.hasPrefix("oauth_") {
                        
                        if OAuthHeader.isEmpty {
                            OAuthHeader += "OAuth "
                        } else {
                            OAuthHeader += ", "
                        }
                        OAuthHeader += "\(encodedKey)=\"\(encodedValue)\""
                        
                    } else {
                        if queryString.isEmpty == false {
                            queryString += "&"
                        }
                        queryString += "\(encodedKey)=\(encodedValue)"
                        
                    }
                }
                
            }
        }
        
        println("Authorization: \(OAuthHeader)")
        
        return queryString

    }
    
    private func generateSignature(params:[String: String]) -> String {
        var start = true
        let method = params["method"]!
        var url: String!
        var baseString = String()
        
        //  sorting and making OAuth Base String for signature..
        if let val = params["path"] {
            url = (baseURL + val).stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
        } else {
            url = params["url"]!.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
        }
        
        let sortedKeysAndValues = sorted(params) { $0.0 < $1.0 }
        for (key, value) in sortedKeysAndValues {
            switch key {
            case "method": OAuthMethod = value
            case "url": break
            case "path": break
            case "format": break
                
            default:
                if !start {
                    baseString += "&"
                } else {
                    start = false
                }
                
                baseString += key.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)! + "=" + value.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
            }
        }
        
        var key = valueForKey("oauth_consumer_secret") + "&"
        
        switch OAuthState {
        case .AuthenticateCode:
            key += valueForKey("request_oauth_token_secret")
        case .AccessToken:
            key += valueForKey("oauth_token_secret")
        default: break
        }
        
        let signatureBaseString = method + "&" + url + "&" + baseString.stringByAddingPercentEncodingWithAllowedCharacters(OAuth1EncodingSet)!
        
        let signature = HMAC_SHA1.hashWithString(signatureBaseString, key: key).base64EncodedStringWithOptions(nil)
        
        println("normalized parameters: \(baseString) \n\n signature base string: \(signatureBaseString) \n\n signature: \(signature)")
        
        return signature
        
    }
    
    private func storeOAuthRequestTokenSecret(response: AnyObject) {
        if let dict = response as? [String: String] {
            encryptToKeyChain(OAuthServiceName+"request_oauth_token", data: dict["oauth_token"]!, updateIfExist: true)
            encryptToKeyChain(OAuthServiceName+"request_oauth_token_secret", data: dict["oauth_token_secret"]!, updateIfExist: true)
        } else {
            println("failed to store Tokens: \(response)")
        }
    }
    
    private func storeOAuthTokenSecret(response: AnyObject) {
        
        keychainHelper.deleteKey(OAuthServiceName+"request_oauth_token")
        keychainHelper.deleteKey(OAuthServiceName+"request_oauth_token_secret")
        keychainHelper.deleteKey(OAuthServiceName+"oauth_verifier")
        
        if let dict = response as? [String: String] {
            
            for (key, value) in dict {
                encryptToKeyChain(OAuthServiceName+"\(key)", data: value)
            }
            
            //  Access user profile
            OAuthState = .AccessToken
            createDataTask(OAuthEndPointKeys.UserProfileURL.rawValue)
            
        } else {
            println("failed to store Tokens: \(response)")
        }
    }
    
    private func storeOAuthVerifier(response: AnyObject) {
        if let dict = response as? [String: String] {
            let key = "oauth_verifier"
            encryptToKeyChain(OAuthServiceName+"\(key)", data: dict[key]!, updateIfExist: true)
        } else {
            println("failed to store oauth_verifier: \(response)")
        }
    }
    
    private func valueForKey(key: String) -> String {
        switch key {
        case "oauth_consumer_key": return OAuthServiceKey
        case "oauth_consumer_secret": return OAuthServiceSecret
        default: return decryptToKeyChain(OAuthServiceName+"\(key)")
        }
    }
    
}

extension OAuth1: OAuthWebResponse {
    
    func responseURL(url: NSURL) {
        
        if let path = url.path, query = url.query {
            switch path {
            case "/oauth1/twitter":
            storeOAuthVerifier(parseResponseString(query, format: OAuthResponseParseFormat)!)
            
            // we got the verifier, lets authorize the verifier, to get final credentials
            OAuthState = .AuthenticateCode
            createDataTask(OAuthEndPointKeys.AuthenticateUserCodeForAccessTokenURL.rawValue)
                
            default: println("response: path:\(path) query:\(query)")
            }
            
        }
    }
}

extension OAuth1: NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    public override func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        var response: AnyObject?
        let path = task.originalRequest.URL!.host! + task.originalRequest.URL!.path!
        
        if error != nil {
            println("\nRequestError: \(responseError[path])")
            if let delgate = delegate {
                delgate.requestFailedWithError(OAuthServiceName, path: path, error: error!.description)
            }
            
            return
        }
        
        if let data = responseData[path] {
            
            response = praseResponse(data, format: OAuthResponseParseFormat)
            
            //  Release the NSData response object
            responseData.removeValueForKey(path)
            
        } else {
            if let delgate = delegate {
                delgate.requestCompleteWithError(OAuthServiceName, path: path, response: responseError[path]!)
            }
            return
        }
        
        if response == nil {
            return
        }
        
        if OAuthState != .AccessToken {
            println("\nResponse (bytes: \(task.countOfBytesExpectedToReceive)): \(response)")
        } else {
            println("\nResponse (bytes: \(task.countOfBytesExpectedToReceive))")
        }
        
        switch OAuthState {
        case .RequestToken:
            storeOAuthRequestTokenSecret(response!)
            authenticationRequestURL()
        case .AuthenticateCode:
            storeOAuthTokenSecret(response!)
            if let delgate = delegate {
                delgate.requestComplete(OAuthServiceName, path: path, response: response!)
            }
            
        case .RefreshAccessToken: break
        case .ValidateAccessToken: break
        case .RevokeAccessToken: break
        case .AccessToken:
            if let delgate = delegate {
                delgate.requestComplete(OAuthServiceName, path: path, response: response!)
            }
            
        default: break
            
        }
    }
    
    public func praseResponse(data: NSData, format: String) -> AnyObject? {
        
        switch format {
        case "json":
            
            var error: NSError?
            let response: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &error)
            if error != nil || response == nil {
                println("Json Error: \(error)")
                return nil
            } else {
                return response!
            }
            
        case "xml": return nil  //  we may not support this format in this version..
        default: //  will be parsed as plain text... format type will guide to parse the response
            //  OAuthSDK uses case is only to parse the Request, Authenticate and Authorize Tokens.
            //  for Twitter, this is "&="
            if let dataString = data.toString() {
                
                return parseResponseString(dataString, format: format)
            }
            
            return nil
        }
    }
    
    private func parseResponseString(data: String, format: String) -> AnyObject? {
        let whiteSpace = NSCharacterSet(charactersInString: format)
        let words = data.componentsSeparatedByCharactersInSet(whiteSpace)
        
        var response = [String: String]()
        for (var i=0; i<words.count; i += 2) {
            response[words[i]] = words[i+1]
        }
        return response
    }
}

