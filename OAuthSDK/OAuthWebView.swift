//
//  OAuthWebView.swift
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 15/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit

public enum Properties: Int {
    case kUINavigationBar = 0x200
    case kUIWebView
    case kUITableView
}

public class OAuthWebView: UIView {
    
    let activityIndicator: UIActivityIndicatorView
    weak var oauthWebResponseDelegate: OAuthWebResponse?
    weak var webview: UIWebView?
    var shouldDismiss = false
    init(delegate: OAuthWebResponse, parent:UIView) {
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        
        oauthWebResponseDelegate = delegate
        
        super.init(frame: UIScreen.mainScreen().bounds)
        
        let navBarItem = UINavigationItem(title: (delegate as! OAuthClient).OAuthServiceName)
        
        let rightBarItem = UIBarButtonItem(customView: activityIndicator)
        rightBarItem.tintColor = UIColor.blueColor()
        
        navBarItem.setRightBarButtonItem(rightBarItem, animated: false)
        
        if let navBar = parent.viewWithTag(Properties.kUINavigationBar.rawValue) as? UINavigationBar {
                navBar.pushNavigationItem(navBarItem, animated: true)
        }
        
        let webView = UIWebView(frame: UIScreen.mainScreen().bounds)
        webView.scrollView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        webView.scrollView.contentOffset = CGPoint(x: 0, y: -64)
        webView.scalesPageToFit = true
        webView.delegate = oauthWebResponseDelegate
        addSubview(webView)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        webview = webView
        tag = Properties.kUIWebView.rawValue
        alpha = 0
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        
        pushAnimateOAuthWebView()
    }
    
    func loadRequestURL(url: String) {
        let req = NSURLRequest(URL: NSURL(string: url)!)
        webview!.loadRequest(req)
    }
    
    public func pushAnimateOAuthWebView(reverse: Bool = false) {
        let size = UIScreen.mainScreen().bounds.size
        alpha = 1.0
        
        let posAnim = CABasicAnimation(keyPath: "position.x")
        if reverse {
            posAnim.fromValue = size.width/2
            posAnim.toValue = size.width + size.width/2
        } else {
            posAnim.fromValue = size.width + size.width/2
            posAnim.toValue = size.width/2
        }
        posAnim.duration = 0.3
        posAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        layer.addAnimation(posAnim, forKey: "position")
        
        if reverse {
            removeFromSuperview()
        }
    }
    
    func navigateBack() {
        shouldDismiss = true
        
        activityIndicator.stopAnimating()
        
        if let navBar = self.superview!.viewWithTag(Properties.kUINavigationBar.rawValue) as? UINavigationBar {
            
            navBar.popNavigationItemAnimated(true)
        }
        
    }
    
    public func isDismissing() -> Bool {
        return shouldDismiss
    }
    
}
