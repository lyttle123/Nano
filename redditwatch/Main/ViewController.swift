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
	var switchState = UserDefaults.standard.object(forKey: "switchState") as? Bool ?? false
	
	
	var wcSession: WCSession!
	
	@IBOutlet weak var proButton: UIButton!
	override func viewWillAppear(_ animated: Bool) {
		UserDefaults.standard.removeObject(forKey: "Pro")
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
				
				sendData().superSend(data: ["defaultSubreddit": true], completionHandler: {finished in
					print(finished)
				})
				defaultSubredditField.isEnabled = true
			} else{
				sendData().superSend(data: ["defaultSubreddit": false], completionHandler: {finished in
					print("Finished")
					
				})
				print("Print setting to false")
				UserDefaults.standard.set(false, forKey: "switchState")
				defaultSubredditField.isEnabled = false
			}
			
		}
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		print("recieved")
			
	}
	
	@IBAction func switchImageRes(_ sender: Any) {
		print("switching")
		if let sender = sender as? UISwitch{
			switch sender.isOn{
			case true:
				UserDefaults.standard.set(true, forKey: "highResImage")
				sendData().superSend(data: ["highResImage": true], completionHandler: {finished in
					print(finished)
				})
			case false:
				sendData().superSend(data: ["highResImage": false], completionHandler: {finished in
					print(finished)
				})
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
				
				sendData().superSend(data: ["defaultSubreddit": sub], completionHandler: {finished in
					print(finished)
					
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

