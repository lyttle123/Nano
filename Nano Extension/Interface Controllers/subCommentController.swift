//
//  subCommentController.swift
//  watchapp Extension
//
//  Created by Will Bishop on 21/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import WatchKit
import Foundation
import SwiftyJSON

class subCommentController: WKInterfaceController {
    
    @IBOutlet var commentLabel: WKInterfaceLabel!
	var reddit = RedditAPI()
	
    var comments = [String: JSON]()
    var idList = [String]()
    var reduce = commentController()
    var post = JSON()
    @IBOutlet var repliesTable: WKInterfaceTable!
	
	

    override func awake(withContext context: Any?) {
	
		self.setTitle("Comments")
		addMenuItem(with: WKMenuItemIcon.info, title: "Back to Posts", action: #selector(backToPosts))
        super.awake(withContext: context)
        if let js = context as? JSON{
            post = js
            commentLabel.setText(js["body"].string!)
            //    print(js["replies"])
			if let replies = js["replies"]["data"]["children"].array{
				for (_, element) in replies.enumerated(){
					let id = element["data"]["id"]
					idList.append(id.string!)
					if let _ = element["data"]["body"].string{
						comments[id.string!] = element["data"]
						
					}
				}
			}
        }
		print("Let's make do with: ")
		print(comments.count)
        repliesTable.setNumberOfRows(comments.count, withRowType: "replyCell")
        for (index, element) in idList.enumerated(){
            let comment = comments[element]
            if let row = repliesTable.rowController(at: index) as? commentController{
                if let comment = comment{
                    guard let body = comment["body"].string, let score = comment["score"].int, let user = comment["author"].string else{
                        print("Returning")
                        return}
                    if comment["author"].string! == UserDefaults().string(forKey: "selectedAuthor"){
                        row.userLabel.setTextColor(UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0))
                    }
					if let replyCount = comment["replies"]["data"]["children"].array{
						if let _ = replyCount.last!["data"]["body"].string{
							row.replies = 4
							row.replyCount.setText("\(String(describing: replyCount.count)) Replies")
						} else{
							row.replies = replyCount.count - 1
							row.replyCount.setText("\(String(describing: replyCount.count - 1)) Replies")
							
						}
						
					}
					if let gildedCount = comment["gilded"].int{
						if gildedCount > 0{
							row.gildedIndicator.setHidden(false)
							print(gildedCount)
							row.gildedIndicator.setText("\(gildedCount * "•")")
							
						} else{
							print(gildedCount)
							row.gildedIndicator.setHidden(true)
						}
					} else
					{
						print("couldn't find gild")
					}
					if let distin = comment["distinguished"].string{
						if distin == "moderator"{
							row.userLabel.setTextColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0))
							
						} else if distin == "admin"{
							row.userLabel.setTextColor(UIColor(red:0.91, green:0.30, blue:0.24, alpha:1.0))
							
						}
						
						
					}
                    row.nameLabel.setText(body)
                    row.scoreLabel.setText("↑ " + String(describing: score) + " | ")
                    row.userLabel.setText(user)
					    
					if let newTime = comment["created_utc"].float{
						
						row.timeLabel.setText(TimeInterval().differenceBetween(newTime))
					}
					
                    
                }
            }
        }
		repliesTable.scrollToRow(at: 0)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	@objc func backToPosts(){
		self.popToRootController()
	}
	@IBAction func postReply() {
		
		guard let id = post["id"].string else {return}
		presentTextInputController(withSuggestions: ["No"], allowedInputMode: .plain, completion: { (arr: [Any]?) in
			if let arr = arr{
				if let comment = arr.first as? String{
					self.reddit.post(commentText: comment, parentId: id, type: "comment", completionHandler: {js in
						print(js)
						guard let dat = js["json"]["data"]["things"].array else{return}
						guard let first = dat.first else {return}
						
						let postedComment = first["data"]
						
						
						if let author = postedComment["author"].string, let body = postedComment["body"].string{
							
							print("Created")
							let idx = NSIndexSet(index: 0)
							self.repliesTable.insertRows(at: idx as IndexSet, withRowType: "replyCell")
							if let row = self.repliesTable.rowController(at: 0) as? commentController{
								row.scoreLabel.setText("↑ 1 |")
								row.timeLabel.setText("Just Now")
								row.gildedIndicator.setHidden(true)
								row.replyCount.setText("0 Replies")
								row.userLabel.setText(author)
								row.nameLabel.setText(body)
								print("Set")
								self.repliesTable.scrollToRow(at: 0)
							}
						}
						
					})
				}
			}
		})
	}
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		
		if let _ = repliesTable.rowController(at: rowIndex) as? commentController{
			WKInterfaceDevice.current().play(WKHapticType.click)
			self.pushController(withName: "subComment", context: comments[idList[rowIndex]])
			
		}
    }
	@IBOutlet var upvoteButton: WKInterfaceButton!
	@IBOutlet var saveButton: WKInterfaceButton!
	@IBOutlet var downvoteButton: WKInterfaceButton!
	var upvoted = false
	var downvoted = false
	@IBAction func upvoteComment() {
		guard let id = post["id"].string else{ return}
		if !upvoted{
			upvoted = true
			downvoted = false
			reddit.vote(1, id: id, type: "comment")
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor(red:0.95, green:0.61, blue:0.07, alpha:1.0))
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
		} else{
			upvoted = false
			downvoted = false
			reddit.vote(0, id: id, type: "comment")
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)

		}
	}
	@IBAction func downvoteComment() {
		guard let id = post["id"].string else{ return}
		if !downvoted{
			downvoted = true
			upvoted = false
			reddit.vote(-1, id: id, type: "comment")
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor(red:0.16, green:0.50, blue:0.73, alpha:1.0))
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
			
		} else{
			upvoted = false
			downvoted = false
			reddit.vote(0, id: id, type: "comment")
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
			
		}
	}
	@IBAction func saveComment() {
		guard let id = post["id"].string else{ return}
		reddit.save(id: id, type: "comment")
		
	}
	
}
