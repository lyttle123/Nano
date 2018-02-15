//
//  quickAccessController.swift
//  
//
//  Created by Will Bishop on 4/2/18.
//

import UIKit
import WatchConnectivity

class quickAccessController: UIViewController, UITableViewDataSource, UITableViewDelegate, WCSessionDelegate {
	
	
	@IBOutlet weak var quickAccessSubreddits: UITableView!
	var subreddits = UserDefaults.standard.object(forKey: "quickSubreddits") as? [String] ?? ["Popular","All","Funny"]
	var savedSubs = UserDefaults.standard.object(forKey: "quickSubreddits") as? [String] ?? ["Popular","All","Funny"]
	var wcSession: WCSession!
	var reddit = RedditAPI()
	var height = CGFloat()
	
	override func viewDidLoad() {

		super.viewDidLoad()
		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

		self.navigationItem.rightBarButtonItem = self.editButtonItem
		if let bool = UserDefaults.standard.object(forKey: "pro") as? Bool{
			if bool{
				subreddits.append("Add another subreddit")
			} else{
				subreddits.append("Pro users can add more than 5 subreddits")
				
			}
			
			
		} else{
			subreddits.append("Pro users can add more than 5 subreddits")
		}
		quickAccessSubreddits.delegate = self
		quickAccessSubreddits.dataSource = self
		quickAccessSubreddits.tableFooterView = UIView()
		print(subreddits)
		NotificationCenter.default.addObserver(self, selector: #selector(self.loadSubreddits(_:)), name: NSNotification.Name(rawValue: "loadSubreddits"), object: nil)
		if let refresh_token = UserDefaults.standard.object(forKey: "refresh_token") as? String{
			reddit.getAccessToken(grantType: "refresh_token", code: refresh_token, completionHandler: { result in
				print("Got back \(result)")
				print("Saving \(String(describing: result["access_token"]))")
				UserDefaults.standard.set(result["access_token"]!, forKey: "access_token")
				self.reddit.access_token = result["access_token"]!
				self.reloadSubscriptions()
				
			})
			
		} else{
			print("wouldn't let")
		}
		
		// Do any additional setup after loading the view.
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue{
			if height.isZero{
				height = keyboardSize.height
			}
			if view.frame.origin.y == 0{
				self.view.frame.origin.y -= height
			}
		}
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			if view.frame.origin.y != 0 {
				self.view.frame.origin.y += height
			}
		}
	}
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		quickAccessSubreddits.setEditing(editing, animated: true)
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func reloadSubscriptions(){
		self.reddit.getSubscriptions(completionHandler: { js in
			if let json = js{
				if let array = json["data"]["children"].array{
					let subs = (array.map {$0["data"]["display_name"].stringValue.lowercased()}).sorted()
					if let bool = UserDefaults.standard.object(forKey: "pro") as? Bool{
						if bool{
							self.savedSubs = subs
							self.subreddits = subs
							self.subreddits.append("Add another subreddit")
							UserDefaults.standard.set(self.savedSubs, forKey: "quickSubreddits")
							
							self.sendSubredditsToWatch()
							self.quickAccessSubreddits.reloadData()
						} else{
							print("Not pro")
							self.savedSubs = Array(subs.dropLast(subs.count - 5))
							self.subreddits = Array(subs.dropLast(subs.count - 5))
							self.subreddits.append("Please purchase Pro to have more subscriptions")
							UserDefaults.standard.set(self.savedSubs, forKey: "quickSubreddits")
							self.sendSubredditsToWatch()
							self.quickAccessSubreddits.reloadData()
						}
						
						
					} else{
						print("Not pro")
						self.savedSubs = Array(subs.dropLast(subs.count - 5))
						print(self.savedSubs)
						self.subreddits = Array(subs.dropLast(subs.count - 5))
						self.subreddits.append("Please purchase Pro to have more subscriptions")
						UserDefaults.standard.set(self.savedSubs, forKey: "quickSubreddits")
						self.sendSubredditsToWatch()
						self.quickAccessSubreddits.reloadData()
					}
				}
			}})
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.yellow
		self.reloadSubscriptions()
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		//
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.blue
	}
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Done")
	}
	func sessionDidDeactivate(_ session: WCSession) {
		//
		
	}
	
	@objc func loadSubreddits(_ notification: NSNotification){
		self.view.endEditing(true)
		if let sub = notification.userInfo?["text"] as? String{
			savedSubs.append(sub)
			UserDefaults.standard.set(savedSubs, forKey: "quickSubreddits")
			
			reddit.subscribe(to: sub, action: "sub", completionHandler: {code in
				if code == 200{
					self.reloadSubscriptions()
					self.sendSubredditsToWatch()
				}
			})
			
			
			
		} else{
			print("Couldn't get sub")
		}
	}
	
	func sendSubredditsToWatch(){
		
		sendData().superSend(data: ["phrases": savedSubs])
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return subreddits.count 
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = quickAccessSubreddits.dequeueReusableCell(withIdentifier: "quickSubreddit") as! quickSubredditCell
		print(indexPath.row)
		
		cell.subreddit = subreddits[indexPath.row]
		
		cell.disableInput()
		cell.update()
		return cell
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let newIndex = IndexPath(row: indexPath.row + 1, section: 0)
		
		
		
		guard let cell = quickAccessSubreddits.cellForRow(at: indexPath) as? quickSubredditCell else {return}
		if cell.subredditLabel.text == "Add another subreddit"{
			subreddits.append("Add another subreddit")
			quickAccessSubreddits.insertRows(at: [newIndex], with: .automatic)
			
			cell.subredditLabel.isUserInteractionEnabled = true
			cell.subredditLabel.text = ""
			cell.subredditLabel.becomeFirstResponder()
			tableView.deselectRow(at: indexPath, animated: true)
			
		}
	}
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let delete = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete"){(UITableViewRowAction,NSIndexPath) -> Void in
			print(NSIndexPath)
			print(self.savedSubs[indexPath.row])
			self.reddit.subscribe(to: self.savedSubs[indexPath.row], action: "unsub", completionHandler: {code in
				if code == 200{
					self.savedSubs.remove(at: indexPath.row)
					self.subreddits.remove(at: indexPath.row)
					print(self.savedSubs)
					
					UserDefaults.standard.set(self.savedSubs, forKey: "quickSubreddits")
					self.quickAccessSubreddits.deleteRows(at: [indexPath], with: .automatic)
					self.reloadSubscriptions()
					self.sendSubredditsToWatch()
				}
			})
			
		}
		return [delete]
	}
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if indexPath.row == subreddits.count - 1{ //If it's the last cell, don't edit it
			return false
		} else{ //CHANGE THIS TO TRUE
			return true
		}
	}
	
	
}

class quickSubredditCell: UITableViewCell, UITextFieldDelegate{
	
	@IBOutlet weak var subredditLabel: UITextField!
	var subreddit: String?
	
	func update(){
		subredditLabel.autocorrectionType = .no
		subredditLabel.text = subreddit
		subredditLabel.delegate = self
	}
	func disableInput(){
		subredditLabel.isUserInteractionEnabled = false
	}
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		
		guard var sub = textField.text else {return false}
		
		if sub.range(of: "r/") != nil{
			sub = sub.replacingOccurrences(of: "r/", with: "")
		}
		if sub.characters.first == "/"{
			sub = sub.replacingOccurrences(of: "/", with: "")
		}
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loadSubreddits"), object: nil, userInfo: ["text": textField.text!])
		
		return true
	}
	
}
