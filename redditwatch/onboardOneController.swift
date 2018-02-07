//
//  onboardOneController.swift
//  redditwatch
//
//  Created by Will Bishop on 5/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import Foundation
import UIKit
import WatchConnectivity
import SafariServices


class onboardOneController: UIViewController, WCSessionDelegate, SFSafariViewControllerDelegate{
	
	@IBOutlet weak var welcomeMessage: UILabel!
	@IBOutlet weak var launchOnDevice: UILabel!
	@IBOutlet weak var connectButton: UIButton!
	var authSession: SFAuthenticationSession?
	var wcSession: WCSession!
	var reddit = RedditAPI()
	
	override func viewWillAppear(_ animated: Bool) {
		if let bool = UserDefaults.standard.object(forKey: "setup") as? Bool{
			print(bool)
			if bool{
				connected()
			}
		} else{
			print("Wouldn't let")
		}
		
	}
	
	func connected(){
		DispatchQueue.main.async {

			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			//let mainController = storyboard.instantiateViewController(withIdentifier: "tabcontrollerforMain") as UIViewController
			let mainController = storyboard.instantiateInitialViewController()
			
			let appDelegate =  UIApplication.shared.delegate as! AppDelegate
				appDelegate.window?.rootViewController = mainController
			
		}

	}
	override func viewDidLoad() {
		connectButton.alpha = 0
		
	}
	override func viewDidAppear(_ animated: Bool) {
		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
	}
	func sessionDidBecomeInactive(_ session: WCSession) {
		print("INACTIVATE")
	}
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Done")
	}
	func sessionDidDeactivate(_ session: WCSession) {
		print("DEACTIVATED")
	}
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		print(message)
		if let launched = message["appLaunched"] as? Bool{
			if launched{
				DispatchQueue.main.async {
					if (UserDefaults.standard.object(forKey: "setup") as? Bool) != nil{
						//
					} else{
						UIView.animate(withDuration: 0.5, animations: {
							print("Animating")
							self.launchOnDevice.alpha = 0
							self.connectButton.alpha = 1
						})
						
					}
					
				}
			}
		}
		if let setup = message["setup"] as? Bool{
			if setup{
				self.connectButton.titleLabel?.text = "Connected to Reddit"
				UserDefaults.standard.set(true, forKey: "setup")
				UserDefaults.standard.set(true, forKey: "connected")
				
				self.connected()
			}
		}
	}
	func sendToWatch(result: [String: Any]){
		wcSession.activate()
		
		self.wcSession.sendMessage(result, replyHandler: { reply in
			if let success = reply["success"] as? Bool{
				if success{
					DispatchQueue.main.async {
						self.connectButton.titleLabel?.text = "Connected to Reddit"
						UserDefaults.standard.set(true, forKey: "setup")
						UserDefaults.standard.set(true, forKey: "connected")
						
						self.connected()
					}
					
				}
			}
		}, errorHandler: { error in
			print(error.localizedDescription)
			self.sendToWatch(result: result)
		})
		self.wcSession.transferUserInfo(result)
	}
	@IBAction func connectToReddit(_ sender: Any) {
		let callbackUrl  = "redditwatch://redirect"
		let authURL = URL(string: "https://www.reddit.com/api/v1/authorize?client_id=uUgh0YyY_k_6ow&response_type=code&state=not_that_important&redirect_uri=redditwatch://redirect&duration=permanent&scope=identity%20edit%20flair%20history%20modconfig%20modflair%20modlog%20modposts%20modwiki%20mysubreddits%20privatemessages%20read%20report%20save%20submit%20subscribe%20vote%20wikiedit%20wikiread")
		//Initialize auth session
		self.authSession = SFAuthenticationSession(url: authURL!, callbackURLScheme: callbackUrl, completionHandler: { (callBack:URL?, error:Error? ) in
			guard error == nil, let successURL = callBack else {
				print(error!)
				print("error")
				return
			}
			
			
			self.connectButton.setTitle("Connecting...", for: .normal)
			print(successURL)
			
			let user = self.getQueryStringParameter(url: (successURL.absoluteString), param: "code")
			if let code = user{
				print("Going")
				RedditAPI().getAccessToken(grantType: "authorization_code", code: code, completionHandler: {result in

					print(result)
					self.connectButton.isEnabled = false
					
					self.sendToWatch(result: result)
					
				})
			} else {
				self.connectButton.isEnabled = true
				self.connectButton.setTitle("Connect To Reddit", for: .normal)
			}
		})
		self.authSession?.start()
	}
	func getQueryStringParameter(url: String, param: String) -> String? {
		guard let url = URLComponents(string: url) else { return nil }
		return url.queryItems?.first(where: { $0.name == param })?.value
	}
	
}
