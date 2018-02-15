//
//  InterfaceController.swift
//  watchapp Extension
//
//  Created by Will Bishop on 20/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class sendData: NSObject, WCSessionDelegate{
	#if os(iOS)
		func sessionDidBecomeInactive(_ session: WCSession) {
			print("Inactive")
		}
	
		func sessionDidDeactivate(_ session: WCSession) {
			print("Deactive")
		}
	#endif
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Complete")
	}
	

	
	var wcSession: WCSession?
	
	func superSend(data: [String: Any], reliable: Bool = false){
		wcSession?.sendMessage(data, replyHandler: {reply in
			print(reply)
		}, errorHandler: {error in
			print(error.localizedDescription)
			if error != nil{
				self.wcSession?.transferUserInfo(data)
			}
		})
		if reliable{
			do {
				try wcSession?.updateApplicationContext(data)
			} catch{
				print(error.localizedDescription)
			}
			
		}
	}
	override init() {
		super.init()
		wcSession = WCSession.default
		wcSession?.delegate = self
		wcSession?.activate()
	}
	
	
}

