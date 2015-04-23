//
//  OAuthClient.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 15/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit
import Sodium

public enum OAuthEndPointKeys: String {
    case RequestTokenURL = "requestToken"
    case AuthenticateUserURL = "authenticateUser"
    case AuthenticateUserCodeForAccessTokenURL = "authenticateCode"
    case RefreshAccessTokenURL = "refreshAuthorizToken"
    case ValidateAccessTokenURL = "validateAuthorizToken"
    case RevokeAccessTokenURL = "revokeAuthorizToken"
    case UserProfileURL = "profile"
}

public enum OAuthClientState {
    case None
    case RequestToken
    case AuthenticateUser
    case AuthenticateCode
    case ValidateAccessToken
    case RefreshAccessToken
    case RevokeAccessToken
    case AccessToken
}

protocol OAuthWebResponse: class, UIWebViewDelegate {
     func responseURL(url: NSURL)
}

public protocol OAuthRequestResponse: class {
    func requestComplete(serviceName: String, path: String, response: AnyObject)
    func requestCompleteWithError(serviceName: String, path: String, response: String)
    func requestFailedWithError(serviceName: String, path: String, error: String)
}

public class OAuthClient: NSObject {
    
    let baseURL: String
    let OAuthServiceName: String
    var OAuthServiceKey: String!
    var OAuthServiceSecret: String!

    var OAuthEndPoints = [String: [String: String]]()
    
    var OAuthURL = ""
    var OAuthMethod = ""
    
    var session: NSURLSession!
    var responseData = [String: NSMutableData]()
    var responseError = [String: String]()
    
    var OAuthState:OAuthClientState = .None
    public weak var delegate: OAuthRequestResponse? = nil
    
    init(config: [String:String]) {
        
        baseURL = config["base_url"]!
        OAuthServiceName = config["service"]!
        
        for (key, value) in config {
            switch key {
            case "consumer_key": fallthrough
            case "client_id":
                OAuthServiceKey = value
            case "consumer_secret": fallthrough
            case "client_secret":
                OAuthServiceSecret = value
                
            default: break
            }
        }
        
        if keychainHelper.checkAndUpdateValueForKey(OAuthServiceName + " token") {
            OAuthState = .AccessToken
        }
        
    }
    
    deinit {
        delegate = nil
        session.invalidateAndCancel()
    }
    
    public func encryptToKeyChain(key: String, data: String, updateIfExist: Bool = false) {
        let sodium = Sodium()!
        let message = data.toData()!
        let secretKey = sodium.secretBox.key()!
        let encrypted: NSData = sodium.secretBox.seal(message, secretKey: secretKey)!
        let dict = ["key":secretKey, "data":encrypted]
        
        if updateIfExist {
            keychainHelper.checkAndUpdateValueForKey(key, updateValue: dict.toData()!)
        } else {
            keychainHelper.storeDataForKey(key, value: dict.toData()!)
        }
    }
    
    public func decryptToKeyChain(key: String) -> String {
        let sodium = Sodium()!
        let code = keychainHelper.getValueForKey(key)!.toDictionary()!
        let key = code["key"]! as! NSData
        let data = code["data"]! as! NSData
        
        return sodium.secretBox.open(data, secretKey: key)!.toString()!
    }
    
    public func addEndPoint(key: String, value:[String:String]) {
        
        OAuthEndPoints[key] = value

    }
    
    public func state() -> OAuthClientState {
        return OAuthState
    }
    
}

extension OAuthClient: UIWebViewDelegate {
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let oauthWebView = webView.superview as! OAuthWebView
        
        if request.URL!.host == "localhost" || request.URL!.host == "127.0.0.1" {
            
            oauthWebView.oauthWebResponseDelegate!.responseURL(request.URL!)
            oauthWebView.navigateBack()
            
            return false
        }
        
        oauthWebView.activityIndicator.startAnimating()
        
        return true
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        (webView.superview as! OAuthWebView).activityIndicator.stopAnimating()
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        
        if OAuthState != .AuthenticateUser {
            return
        }
        
        let oauthWebView = webView.superview as! OAuthWebView
        
//        if let info = error.userInfo {
//            for (key, value) in info {
//                switch key {
//                case "NSErrorFailingURLKey":
//                    
//                    if let url = value as? NSURL {
//                        if url.host == "localhost" || url.host == "127.0.0.1" {
//                            
//                            oauthWebView.oauthWebResponseDelegate.responseURL(url)
//                            oauthWebView.navigateBack()
//                            return
//                        }
//                    }
//                    
//                case "NSErrorFailingURLStringKey":
//                    
//                    if let url = NSURL(string: value as! String) {
//                        if url.host == "localhost" || url.host == "127.0.0.1" {
//                            
//                            oauthWebView.oauthWebResponseDelegate.responseURL(url)
//                            oauthWebView.navigateBack()
//                            return
//                        }
//                    }
//                    
//                default: break
//                }
//            }
//        }
        
        println("Load Url Error: \(error)")
        
        if !webView.canGoBack {
            oauthWebView.navigateBack()
        }
        
    }
}


extension OAuthClient: NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        completionHandler(NSURLSessionResponseDisposition.Allow)
        
        let path = dataTask.originalRequest.URL!.host! + dataTask.originalRequest.URL!.path!
        
        responseError[path] = NSURLResponse.debugDescription()

    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        let path = dataTask.originalRequest.URL!.host! + dataTask.originalRequest.URL!.path!
        
        if responseData[path] == nil {
            responseData[path] = NSMutableData()
        }
        
        data.enumerateByteRangesUsingBlock{[weak self] (pointer: UnsafePointer<()>,
            range: NSRange,
            stop: UnsafeMutablePointer<ObjCBool>) in
            let newData = NSData(bytes: pointer, length: range.length)
            self!.responseData[path]!.appendData(newData) }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        //  Save the file from location to app document folder or preffered location...
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(Double(totalBytesWritten)/Double(totalBytesExpectedToWrite))
        
    }
}
