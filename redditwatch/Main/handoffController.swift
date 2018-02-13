//
//  handoffController.swift
//  redditwatch
//
//  Created by Will Bishop on 4/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import UIKit
import WatchConnectivity

class handoffController: UIViewController, WCSessionDelegate, UITableViewDelegate, UITableViewDataSource {

	
	let clients = ["Reddit", "Apollo", "Narwhal"]
	var availableClients = [String]()
	var selectedClient = UserDefaults.standard.object(forKey: "selectedClient") as? String ?? "reddit"
	var wcSession: WCSession!
	
	@IBOutlet weak var clientTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.blue

		for element in clients.enumerated(){
			if UIApplication.shared.canOpenURL(URL(string: element.element + "://")!){
				availableClients.append(element.element)
			}
			
		}
		clientTable.delegate = self
		clientTable.dataSource = self
        // Do any additional setup after loading the view.
		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
		
    }
	override func viewDidAppear(_ animated: Bool) {
		if let proUpgrade = UserDefaults.standard.object(forKey: "Pro") as? Bool{
			if !proUpgrade{
				let alert = UIAlertController(title: "Handoff", message: "Handoff is a feature of the Pro upgrade", preferredStyle: .alert)
				
				self.present(alert, animated: true, completion: nil)
			}
		} else{
			let alert = UIAlertController(title: "Handoff", message: "Handoff is a feature of the Pro upgrade", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {tapped in
				
			}))
			alert.addAction(UIAlertAction(title: "Purchase Pro", style: .default, handler: {tapped in
				self.navigationController?.pushViewController((self.storyboard?.instantiateViewController(withIdentifier: "proController"))!, animated: true)
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
		
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
	
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return availableClients.count
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = clientTable.dequeueReusableCell(withIdentifier: "client")
		cell?.textLabel?.text = availableClients[indexPath.row]
		var pro: Bool
		if let proUpgrade = UserDefaults.standard.object(forKey: "Pro") as? Bool{
			pro = proUpgrade
		}else{
			pro = false
		}
		if availableClients[indexPath.row].lowercased() == selectedClient && pro{
			UserDefaults.standard.set(availableClients[indexPath.row].lowercased(), forKey: "selectedClient")
			print("Adding checkmark because \(availableClients[indexPath.row].lowercased()) == \(selectedClient)")
			cell?.accessoryType = .checkmark
		}else{
			cell?.accessoryType = .none
		}
		return cell!
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		selectedClient = (clientTable.cellForRow(at: indexPath)?.textLabel?.text?.lowercased())!
		print(selectedClient)
		UserDefaults.standard.set(selectedClient, forKey: "selectedClient")
		clientTable.reloadData()
	}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
