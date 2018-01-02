//
//  commentController.swift
//  redditwatch
//
//  Created by Will Bishop on 21/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import WatchKit

class commentController: NSObject {

	@IBOutlet var userLabel: WKInterfaceLabel!
	@IBOutlet var nameLabe: WKInterfaceLabel!
	@IBOutlet var timeLabel: WKInterfaceLabel!
	@IBOutlet var scoreLabel: WKInterfaceLabel!
	@IBOutlet var replyCount: WKInterfaceLabel!
	var replies = Int()
}
