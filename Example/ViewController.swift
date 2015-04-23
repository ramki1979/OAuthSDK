//
//  ViewController.swift
//  OAuthSDK Example
//
//  Created by RamaKrishna Mallireddy on 19/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

import UIKit
import OAuthSDK

class AccountsTableViewCell: UITableViewCell {
    let iconLabel: UILabel
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        iconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 44))
        iconLabel.font = UIFont.fontAwesomeOfSize(24)
        iconLabel.text = String.fontAwesomeIconWithName("fa-ban")
        iconLabel.textAlignment = NSTextAlignment.Center
        iconLabel.textColor = UIColor.blueColor()
        
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ViewController: UIViewController {
    
    let cellIdentifier = "accounts"
    let icons = ["fa-apple", "fa-google", "fa-dropbox", "fa-twitter", "fa-windows"]
    let cloudServices = ["iCloud", "Google Drive", "Dropbox", "Twitter", "One Drive"]
    var serviceSelected:Int = -1
    
    var googleDriveClient: GoogleDriveCloud? = nil
    var twitterService: TwitterService? = nil
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidLoad() {
        
        let navBarItem = UINavigationItem(title: "Social Manager")
        let navFrame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64)
        let navBar = UINavigationBar(frame: navFrame)
        let rightBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneBarButton:")
        rightBarItem.tintColor = UIColor.blueColor()
        
        navBarItem.setRightBarButtonItem(rightBarItem, animated: false)
        navBar.pushNavigationItem(navBarItem, animated: false)
        navBar.tag = Properties.kUINavigationBar.rawValue
        navBar.translucent = true
        navBar.delegate = self
        navBar.barStyle = UIBarStyle.Black
        
        
        let tableView = UITableView(frame: view.bounds, style: UITableViewStyle.Grouped)
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.separatorStyle = .SingleLine
        tableView.tag = Properties.kUITableView.rawValue
        tableView.registerClass(AccountsTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        view.addSubview(tableView)
        view.addSubview(navBar)
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func doneBarButton(barButton: UIBarButtonItem) {
        
    }
}

extension ViewController: UINavigationBarDelegate {
    func navigationBar(navigationBar: UINavigationBar, shouldPushItem item: UINavigationItem) -> Bool {// called to push. return NO not to.
        return true
    }
    
    func navigationBar(navigationBar: UINavigationBar, didPushItem item: UINavigationItem) { // called at end of animation of push or immediately if not animated
    }
    
    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {// same as push methods
        
        if let oauthWebview = view.viewWithTag(Properties.kUIWebView.rawValue) as? OAuthWebView {
            if oauthWebview.isDismissing() == false {
                
                if let webview = oauthWebview.subviews[0] as? UIWebView {
                    if webview.canGoBack {
                        webview.goBack()
                        
                        //  The arrow icon is getting disabled visually...
                        for barItemView in navigationBar.subviews as! [UIView] {
                            if barItemView.alpha < 1 {
                                UIView.animateWithDuration(0.30, animations: { barItemView.alpha = 1.0 })
                            }
                        }
                        
                        return false
                    }
                }
            }
        
            oauthWebview.pushAnimateOAuthWebView(reverse: true)
        }
        return true
    }
    
    func navigationBar(navigationBar: UINavigationBar, didPopItem item: UINavigationItem) {
        
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {// return 'depth' of row for hierarchies
        return 5
    }
    
    // Called after the user changes the selection.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        serviceSelected = indexPath.row
        
        switch cloudServices[indexPath.row] {
        case "iCloud": break
        case "Google Drive":
            GoogleDriveOAuth(cloudServices[indexPath.row])
        case "Dropbox": break
        case "Twitter":
            TwitterServiceOAuth(cloudServices[indexPath.row])
        case "One Drive": break
        default: break
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cloudServices.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {// fixed font style. use custom view (UILabel) if you want something different
        return "Cloud Services"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AccountsTableViewCell
        
        cell.iconLabel.frame = CGRect(x: 0, y: 0, width: 80, height: 44)
        cell.iconLabel.text = String.fontAwesomeIconWithName(icons[indexPath.row])
        cell.iconLabel.textAlignment = NSTextAlignment.Center
        cell.textLabel!.text = cloudServices[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
}

extension ViewController {
    
    func GoogleDriveOAuth(title: String) {
        if googleDriveClient == nil {
            googleDriveClient = GoogleDriveCloud(service: title)
        }
        
        if let gd = googleDriveClient {
            
            switch gd.state() {
            case .None: fallthrough
            case .RequestToken: fallthrough
            case .AuthenticateUser:
                
                // The below set the respective URL that webview needs to load for user athentication...
                gd.authenticationRequestURL(self.view)
                
            case .AccessToken:
                showAlertView(title, message: "Already Authorized, You are ready to call \(title) REST API's")
            default: break

            }
            
        }
    }
    
    func TwitterServiceOAuth(title: String) {
        if twitterService == nil {
            twitterService = TwitterService(service: title)
        }
        
        if let twt = twitterService {
            
            switch twt.state() {
            case .None: fallthrough
            case .RequestToken: fallthrough
            case .AuthenticateUser:
                
                // The below set the respective URL that webview needs to load for user athentication...
                twt.authenticationRequestURL(self.view)
                
            case .AccessToken:
                showAlertView(title, message: "Already Authorized, You are ready to call \(title) REST API's")
                
            default: break
                
            }
            
        }

    }
    
    func showAlertView(title: String, message: String) {
        
        if NSClassFromString("UIAlertController") != nil {
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            var alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "Close")
            alert.show()
        }
    }
}

