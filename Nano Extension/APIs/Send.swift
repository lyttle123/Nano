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
	
	func superSend(data: [String: Any], reliable: Bool = false, completionHandler: @escaping (_ finished: Bool) -> Void){
		wcSession?.sendMessage(data, replyHandler: {reply in
			print(reply)
			completionHandler(true)
		}, errorHandler: {error in
			print(error.localizedDescription)
			if error != nil{
				self.wcSession?.transferUserInfo(data)
				completionHandler(true)

			}
		})
		if reliable{
			do {
				try wcSession?.updateApplicationContext(data)
				completionHandler(true)

			} catch{
				print(error.localizedDescription)
				completionHandler(false)

			}
			
		}
	}
	override init() {
		super.init()
		if WCSession.isSupported(){
			wcSession = WCSession.default
			wcSession?.delegate = self
			wcSession?.activate()
			
		}
	}
	
	
}

