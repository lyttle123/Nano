//
//  waitForiPhone.swift
//  watchapp Extension
//
//  Created by Will Bishop on 4/1/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import WatchKit
import WatchConnectivity

class waitForiPhone: WKInterfaceController, WCSessionDelegate {
	var setup = UserDefaults.standard.object(forKey: "setup") as? Bool ?? false
	var reddit = RedditAPI()
	@IBOutlet var getStartedButton: WKInterfaceButton!
	var wcSession: WCSession?
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		wcSession = WCSession.default
		wcSession?.delegate = self
		wcSession?.activate()
//		getStartedButton.setEnabled(false)
//		if let connected = UserDefaults.standard.object(forKey: "connected") as? Bool{
//			if connected {
//				getStartedButton.setEnabled(true)
//			}
//		}
	}
	
	
	@IBAction func getStarted() {
		print("Starting")
		UserDefaults.standard.set(true, forKey: "setup")
		self.dismiss()
	}
	func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
	
		if let refesh_token = userInfo["refresh_token"] as? String{
			print(refesh_token)
			UserDefaults.standard.set(refesh_token, forKey: "refresh_token")
			if let access_token = userInfo["access_token"] as? String{
				UserDefaults.standard.set(access_token, forKey: "access_token")
				
				UserDefaults.standard.set(true, forKey: "connected")
				print("SHould enable")
				if !setup{
					print("moving away")
					self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
						print(error.localizedDescription)
					})
					UserDefaults.standard.set(true, forKey: "setup")
					self.setup = true
					WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("interface", AnyObject.self as AnyObject)])
					
					
					
				}
				self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
					print(error.localizedDescription)
				})
				
				
			}
		} else{
			print("WOULDN'T LET")
		}
	}
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		print(message)
		if let refesh_token = message["refresh_token"] as? String{
			print(refesh_token)
			UserDefaults.standard.set(refesh_token, forKey: "refresh_token")
			if let access_token = message["access_token"] as? String{
				UserDefaults.standard.set(access_token, forKey: "access_token")
				
				UserDefaults.standard.set(true, forKey: "connected")
				print("SHould enable")
				if !setup{
					print("moving away")
					self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
						print(error.localizedDescription)
					})
					UserDefaults.standard.set(true, forKey: "setup")
					WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("interface", AnyObject.self as AnyObject)])
					
					self.setup = true
					
				}
				self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
					print(error.localizedDescription)
				})
				
				
			}
		} else{
			print("WOULDN'T LET")
		}
	}
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Done")
		switch activationState {
		case .activated:
			print("activated")
			if (self.wcSession?.isReachable)!{
				self.wcSession?.sendMessage(["appLaunched": true], replyHandler: nil, errorHandler: { error in
					print(error.localizedDescription)
				})
			} else{
				print("Not reachable")
			}
		default:
			print("not actived")
		}
		print(String(describing: error?.localizedDescription))
		
	}

}
