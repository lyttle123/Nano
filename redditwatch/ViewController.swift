//
//  ViewController.swift
//  redditwatch
//
//  Created by Will Bishop on 20/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import UIKit
import WatchConnectivity
import SafariServices
import Alamofire
import SwiftyJSON
import SAConfettiView


class ViewController: UIViewController, WCSessionDelegate, SFSafariViewControllerDelegate, UITextFieldDelegate {
	@IBOutlet weak var userSubreddits: UITextField!
	var authSession: SFAuthenticationSession?
	
	@IBOutlet weak var defaultSubredditField: UITextField!
	@IBOutlet weak var defaultSubredditSwitch: UISwitch!
	@IBOutlet weak var connectButton: UIButton!
	@IBOutlet weak var highResSwitch: UISwitch!
	var switchState = UserDefaults.standard.object(forKey: "switchState") as? Bool ?? false
	
	
	var wcSession: WCSession!
	
	@IBOutlet weak var proButton: UIButton!
	override func viewWillAppear(_ animated: Bool) {
		
		//proButton.isEnabled = false

		defaultSubredditField.delegate = self
		if let sub = UserDefaults.standard.object(forKey: "defaultSubreddit") as? String{
			defaultSubredditField.text = sub
		}
		if switchState{
			defaultSubredditSwitch.setOn(true, animated: false)
			defaultSubredditField.isEnabled = true
			
		} else{
			defaultSubredditSwitch.setOn(false, animated: false)
			defaultSubredditField.isEnabled = false
		}
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.blue

		
	
		
		
		self.connectButton.isEnabled = false
		connectButton.setTitle("Please launch on watch to connect to Reddit", for: .normal)
		if let bool = UserDefaults.standard.object(forKey: "highResImage") as? Bool{
			highResSwitch.setOn(bool, animated: false)
		} else{
			print("couldn't do bool")
		}
		
		if let b = UserDefaults.standard.object(forKey: "connected") as? Bool{
			if b{
				self.connectButton.isEnabled = false
				self.connectButton.setTitle("Connected to Reddit", for: .normal)
			}
		}
		
		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
		
		// Do any additional setup after loading the view, typically from a nib.
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	func getQueryStringParameter(url: String, param: String) -> String? {
		guard let url = URLComponents(string: url) else { return nil }
		return url.queryItems?.first(where: { $0.name == param })?.value
	}
	func sessionDidBecomeInactive(_ session: WCSession) {
		//
	}
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Done")
	}
	func sessionDidDeactivate(_ session: WCSession) {
		//
	}
	
	
	
	@IBAction func switchDefault(_ sender: Any) {
		if let switchSub = sender as? UISwitch{
			if switchSub.isOn{
				print("Setting to on")
				UserDefaults.standard.set(true, forKey: "switchState")
				wcSession.sendMessage(["defaultSubreddit": true], replyHandler: nil, errorHandler: { errror in
					print(errror)
				})
				defaultSubredditField.isEnabled = true
			} else{
				wcSession.sendMessage(["defaultSubreddit": false], replyHandler: nil, errorHandler: { errror in
					print(errror)
				})
				print("Print setting to false")
				UserDefaults.standard.set(false, forKey: "switchState")
				defaultSubredditField.isEnabled = false
			}
			
		}
	}
	@IBAction func connectToReddit(){
		
		let callbackUrl  = "redditwatch://redirect"
		let authURL = URL(string: "https://www.reddit.com/api/v1/authorize?client_id=uUgh0YyY_k_6ow&response_type=code&state=not_that_important&redirect_uri=redditwatch://redirect&duration=permanent&scope=identity%20edit%20flair%20history%20modconfig%20modflair%20modlog%20modposts%20modwiki%20mysubreddits%20privatemessages%20read%20report%20save%20submit%20subscribe%20vote%20wikiedit%20wikiread")
		//Initialize auth session
		self.authSession = SFAuthenticationSession(url: authURL!, callbackURLScheme: callbackUrl, completionHandler: { (callBack:URL?, error:Error? ) in
			guard error == nil, let successURL = callBack else {
				print(error!)
				print("error")
				return
			}
			self.connectButton.isEnabled = false
			self.connectButton.setTitle("Connecting...", for: .normal)
			print(successURL)
			let user = self.getQueryStringParameter(url: (successURL.absoluteString), param: "code")
			if let code = user{
				print("Going")
				RedditAPI().getAccessToken(grantType: "authorization_code", code: code, completionHandler: {result in
					UserDefaults.standard.set(true, forKey: "connected")
					UserDefaults.standard.set(true, forKey: "setup")
					print(result)
					self.connectButton.isEnabled = false
					self.connectButton.setTitle("Connected To Reddit", for: .normal)
					self.wcSession.sendMessage(result, replyHandler: nil, errorHandler: { error in
						print(error.localizedDescription)
					})
				})
			} else {
				self.connectButton.isEnabled = true
				self.connectButton.setTitle("Connect To Reddit", for: .normal)
			}
		})
		self.authSession?.start()
		
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		print("recieved")
		if let launched = message["appLaunched"] as? Bool{
			if launched{
				DispatchQueue.main.async {
					if (UserDefaults.standard.object(forKey: "setup") as? Bool) != nil{
						//
					} else{
						self.connectButton.isEnabled = true
						self.connectButton.setTitle("Connect To Reddit", for: .normal)
					}
					
				}
			}
		}
		if let setup = message["setup"] as? Bool{
			if setup{
				self.connectButton.isEnabled = false
				self.connectButton.setTitle("Connected to Reddit", for: .normal)
			}
		}
	}
	
	@IBAction func switchImageRes(_ sender: Any) {
		print("switching")
		if let sender = sender as? UISwitch{
			switch sender.isOn{
			case true:
				UserDefaults.standard.set(true, forKey: "highResImage")
				wcSession.sendMessage(["highResImage": true], replyHandler: nil, errorHandler: nil)
			case false:
				wcSession.sendMessage(["highResImage": false], replyHandler: nil, errorHandler: nil)
				UserDefaults.standard.set(false, forKey: "highResImage")
			}
		}
	}
	@IBAction func resetAllData(_ sender: Any) {	UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
		UserDefaults.standard.synchronize()
		print(["a"][1])
	}
	func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return false to ignore.
	{
		UserDefaults.standard.set(textField.text, forKey: "defaultSubreddit")
		if textField.tag == 2{
			//Placeholder
		} else if textField.tag == 3{
			if let sub = textField.text{
				wcSession.sendMessage(["defaultSubreddit": sub], replyHandler: nil, errorHandler: { errror in
					print(errror)
				})
				
			}
		}
		
		
		self.view.endEditing(true)
		
		return true
	}
	
	@IBAction func goToPro(_ sender: Any) {
		self.navigationController?.pushViewController((storyboard?.instantiateViewController(withIdentifier: "proController"))!, animated: true)
	}
	override func restoreUserActivityState(_ activity: NSUserActivity) {
		print("Processing")
		if let id = activity.userInfo!["current"]{
			let instagramHooks = "apollo://reddit.com/\(id)"
			let instagramUrl = URL(string: instagramHooks)!
			if UIApplication.shared.canOpenURL(instagramUrl)
			{
				UIApplication.shared.open(instagramUrl)
				
			} else {
					
				print("No go")
			}
		} else{
			
		}
	}
}

