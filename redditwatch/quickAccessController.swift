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
	
	override func viewDidLoad() {
        super.viewDidLoad()
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.yellow

		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
		
		
		subreddits.append("Add another subreddit")
		quickAccessSubreddits.delegate = self
		quickAccessSubreddits.dataSource = self
		quickAccessSubreddits.tableFooterView = UIView()
		print(subreddits)
		NotificationCenter.default.addObserver(self, selector: #selector(self.loadSubreddits(_:)), name: NSNotification.Name(rawValue: "loadSubreddits"), object: nil)
		
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
		
		if let sub = notification.userInfo?["text"] as? String{
			savedSubs.append(sub)
			UserDefaults.standard.set(savedSubs, forKey: "quickSubreddits")
			sendSubredditsToWatch()
		} else{
			print("Couldn't get sub")
		}
	}
	
	func sendSubredditsToWatch(){
		wcSession.sendMessage(["phrases": savedSubs], replyHandler: {eh in
			print(eh)
		}, errorHandler: { errror in
			print(errror)
		})
		wcSession.transferUserInfo(["phrases": savedSubs])
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
			self.savedSubs.remove(at: indexPath.row)
			self.subreddits.remove(at: indexPath.row)
			print(self.savedSubs)
			UserDefaults.standard.set(self.savedSubs, forKey: "quickSubreddits")
			self.quickAccessSubreddits.deleteRows(at: [indexPath], with: .automatic)
			self.sendSubredditsToWatch()
		}
		return [delete]
	}
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if indexPath.row == subreddits.count - 1{ //If it's the last cell, don't edit it
			return false
		} else{ //Nah you can
			return true
		}
	}

	
}

class quickSubredditCell: UITableViewCell, UITextFieldDelegate{
	
	@IBOutlet weak var subredditLabel: UITextField!
	var subreddit: String?
	
	func update(){
		subredditLabel.text = subreddit
		subredditLabel.delegate = self
	}
	func disableInput(){
		subredditLabel.isUserInteractionEnabled = false
	}
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		subredditLabel.resignFirstResponder()
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
