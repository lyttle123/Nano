//
//  postController.swift
//  watchapp Extension
//
//  Created by Will Bishop on 20/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import WatchKit
import Foundation
import SwiftyJSON
import Alamofire
import SwiftSoup

class postController: WKInterfaceController {
	
	
	
	@IBOutlet var waitIndicator: WKInterfaceLabel!
	@IBOutlet var postCommentButton: WKInterfaceButton!
	@IBOutlet var movieControl: WKInterfaceMovie!
	@IBOutlet var postComments: WKInterfaceLabel!
	@IBOutlet var postScore: WKInterfaceLabel!
	@IBOutlet var postAuthor: WKInterfaceLabel!
	@IBOutlet var progressLabel: WKInterfaceLabel!
	@IBOutlet var upvoteButton: WKInterfaceButton!
	@IBOutlet var downvoteButton: WKInterfaceButton!
	@IBOutlet var savePostButton: WKInterfaceButton!
	@IBOutlet var postTitle: WKInterfaceLabel!
	@IBOutlet var commentsTable: WKInterfaceTable!
	@IBOutlet var postImage: WKInterfaceImage!
	@IBOutlet var postTime: WKInterfaceLabel!
	@IBOutlet var loadingIndicator: WKInterfaceImage!
	@IBOutlet var articleHousing: WKInterfaceGroup!
	@IBOutlet var articleDomain: WKInterfaceLabel!
	@IBOutlet var articleTitle: WKInterfaceLabel!
	
	var reddit = RedditAPI()
	var saved = false
	var comments = [String: JSON]()
	var currentPost = JSON()
	var downvoted = false
	var upvoted = false
	@IBOutlet var postContent: WKInterfaceLabel!
	var ids = [String: Any]()
	var idList = [String]()
	var currentSort = "best"
	var currentSubreddit = String()
	var currentId = String()
	var articleContents = [String: Any]()
	private var _loading: Bool!
	var loading: Bool{
		set{
			if newValue == true{
				loadingIndicator.setImageNamed("Activity")
				loadingIndicator.startAnimating()
				loadingIndicator.setHidden(false)
				_loading = true
				
			} else{
				loadingIndicator.stopAnimating()
				loadingIndicator.setHidden(true)
				_loading = false
			}
		}
		get{
			return _loading
		}
	}
	override func awake(withContext context: Any?) {
		
		
		super.awake(withContext: context)
		
		addMenuItem(with: WKMenuItemIcon.info, title: "Change Sort", action: #selector(changeSort))
		downvoteButton.setHidden(true)
		upvoteButton.setHidden(true)
		savePostButton.setHidden(true)
		articleHousing.setHidden(true)
		
		guard let post = context as? JSON else{
			InterfaceController().becomeCurrentPage()
			return
			
			
		}
	
		if let connected = UserDefaults.standard.object(forKey: "connected") as? Bool{
			if connected {
				downvoteButton.setHidden(false)
				upvoteButton.setHidden(false)
				savePostButton.setHidden(false)
			}
		}
		if let author = post["author"].string{
			postAuthor.setText(author)
		}
		if let newTime = post["created_utc"].float{
			postTime.setText(TimeInterval().differenceBetween(newTime))
		}
		if let score = post["score"].int{
			
			postScore.setText("↑ \(String(score))")
		}
		if let replies = post["num_comments"].int{
			postComments.setText("\(replies) Comments")
		}
		if UserDefaults.standard.object(forKey: "shouldLoadImage") as! Bool{
			if let imagedat = UserDefaults.standard.object(forKey: "selectedThumbnail" + (UserDefaults.standard.object(forKey: "selectedId") as! String)) as? Data{
				postImage.setImageData(imagedat)
				if let image = UIImage(data: imagedat){
					postImage.setRelativeHeight(image.breadthRect.height, withAdjustment: 0)
				}
				
				
			}
			
		}
		if var url = post["url"].string{
			var shouldLoad = true
			
			if url.range(of: "imgur") != nil && url.range(of: "i.imgur") == nil && url.range(of: "/a/") == nil{ //If it's an imgur post, that isn't an album, but also is not a direct link
				let id = url.components(separatedBy: ".com/").last!
				url = "https://i.imgur.com/\(id).png" //Make it one
			}
			if url.range(of: "gifv") != nil && url.range(of: "imgur") != nil{
				shouldLoad = false
				url = url.replacingOccurrences(of: "gifv", with: "mp4")
				
			}
			
			print("Downloading")
			print(url)
			if !shouldLoad{
				shouldLoad = false
				self.postImage.setHidden(true)
				movieControl.setMovieURL(URL(string: url)!)
				movieControl.setLoops(true)
				
				if let imagedat = UserDefaults.standard.object(forKey: "selectedThumbnail" + (UserDefaults.standard.object(forKey: "selectedId") as! String)) as? Data{
					let img = WKImage(imageData: imagedat)
					movieControl.setPosterImage(img)
					
				}
				
				
			} else{
				movieControl.setHidden(true)
			}
			
			if shouldLoad{
				print(url)
				self.progressLabel.setHidden(false)
				self.progressLabel.setText("Downloading...")
				Alamofire.request(url)
					.response { imageData in
						
						if let subreddit = post["subreddit"].string, let id = post["id"].string {
							self.getComments(subreddit: subreddit, id: id)
							self.currentSubreddit = subreddit
							self.currentId = id
							
							
							self.updateUserActivity("com.willbishop.redditwatch.handoff", userInfo: ["current": id, "subreddit": subreddit], webpageURL: nil)
							
							
						} else{
							print("wouldn't let")
						}
						self.progressLabel.setHidden(true)
						print(imageData.data)
						print("FINISHED")
						if let data = imageData.data{
							if let hint = post["post_hint"].string{
								if hint == "image" && url.range(of: "gif") != nil{
									if let b = UIImage.gifImageWithData(data){
										print("Gif")
										self.postImage.setImage(b)
										self.postImage.sizeToFitWidth()
										self.postImage.startAnimating()
									}
								} else{
									let image = UIImage(data: data)
									if image != nil{
										print("setting \(String(describing: image))")
										self.postImage.setImage(image)
										self.postImage.sizeToFitHeight()
									} else{
										print("Sizing now")
										if let text = String.init(data: data, encoding: String.Encoding.utf8) {
											self.articleHousing.setHidden(false)
											print(text)
											var stuff = self.getText(html: text)
											print(stuff)
											if stuff["error"] == nil{
												self.articleDomain.setText(imageData.request?.url?.host)
												self.articleTitle.setText("Read Article")
												if let content = stuff["content"] as? String{
													if content.count as Int > 0{
														self.articleHousing.setHidden(false)
													} else{
														self.articleHousing.setHidden(true)
													}
												}
												if UserDefaults.standard.object(forKey: "shouldLoadImage") as! Bool{
													if let imagedat = UserDefaults.standard.object(forKey: "selectedThumbnail" + (UserDefaults.standard.object(forKey: "selectedId") as! String)) as? Data{
														let image = UIImage(data: imagedat)
														stuff["image"] = image
														
													}
													
												}
												self.articleContents = stuff
												
											}
										}
									}
								}
							
							} else{
								print("NO IMAGE")
								let image = UIImage(data: data)
								if image != nil{
									print("setting \(String(describing: image))")
									self.postImage.setImage(image)
									self.postImage.sizeToFitHeight()
								} else{
									print("MAKING ARTICLE")
									if let text = String.init(data: data, encoding: String.Encoding.utf8) {
										
										var stuff = self.getText(html: text)
										if let content = stuff["content"] as? String{
											if content.count as Int > 0{
												self.articleHousing.setHidden(false)
											} else{
												self.articleHousing.setHidden(true)
											}
										}
										if stuff["error"] == nil{
											
											self.articleDomain.setText(imageData.request?.url?.host)
											
											self.articleTitle.setText("Read Article")
											if UserDefaults.standard.object(forKey: "shouldLoadImage") as! Bool{
												if let imagedat = UserDefaults.standard.object(forKey: "selectedThumbnail" + (UserDefaults.standard.object(forKey: "selectedId") as! String)) as? Data{
													let image = UIImage(data: imagedat)
													stuff["image"] = image
													
												}
												
											}
											self.articleContents = stuff
											
										}
									}
								}
							}
							
							
						} else{
							self.progressLabel.setText("Incompatible Website")
							print("couldn't make image")
						}
					}
					.downloadProgress {progress in
						self.progressLabel.setHidden(false)
						let progresss = String(progress.fractionCompleted * Double(100)).prefix(4)
						if progress.fractionCompleted > 0.0{
							self.progressLabel.setText("Downloading \(progresss)%")
							
						}
						if progress.fractionCompleted == 1.0{
							self.progressLabel.setHidden(true)
						}
				}
					
				
				
			}
			
		} else{
			movieControl.setHidden(true)
		}
		currentPost = post
		UserDefaults.standard.set(post["author"].string, forKey: "selectedAuthor")
		if let content = post["selftext"].string{
			postContent.setText(content.dehtmlify())
		}
		
		if let title = post["title"].string{
			postTitle.setText(title)
		}
		
		// Configure interface objects here.
		
	}
	
	func getText(html: String) -> [String: Any]{
		do {
			let doc: Document = try SwiftSoup.parse(html)
			var article = [String]()
			var returners = [String: String]()
			try? doc.select("p").forEach {
				let text = try? $0.text()
				let components = text?.components(separatedBy: .whitespacesAndNewlines)
				if components!.count > 3{
					article.append(try! $0.text())
				}
				
			
			}
			returners["content"] = article.joined(separator: "\n\n")
			if let title = try? doc.title(){
				returners["title"] = title
			}
			
			return returners
			
		} catch Exception.Error( _, let message) {
			print(message)
			return ["error": message]
		} catch {
			print("error")
			return ["error": "Unknown Error"]
		}
	}
	override func willDisappear() {
		UserDefaults.standard.removeObject(forKey: "selectedThumbnail" + currentId)
		
		Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
			sessionDataTask.forEach {
				if let url = $0.originalRequest?.url?.absoluteString{
					print(url)
					if url.range(of: "thumbs.redditmedia.com") == nil && url.range(of: "api/comment") == nil{
						$0.cancel()
						print("Cancelled \(url)")
					}
				}
				
			}
			uploadData.forEach {
				if let url = $0.originalRequest?.url?.absoluteString{
					print(url)
					if url.range(of: "thumbs.redditmedia.com") == nil && url.range(of: "api/comment") == nil{
						$0.cancel()
						print("Cancelled \(url)")
					}
				}
			}
			downloadData.forEach {
				if let url = $0.originalRequest?.url?.absoluteString{
					print(url)
					if url.range(of: "thumbs.redditmedia.com") == nil && url.range(of: "api/comment") == nil{
						$0.cancel()
						print("Cancelled \(url)")
					}
				}
			}
		}
	}
	
	func getComments(subreddit: String, id: String, sort: String = "best"){
		comments.removeAll()
		ids.removeAll()
		idList.removeAll()
		
		
		loading = true
		reddit.getComments(subreddit: subreddit, id: id, sort: sort, completionHandler: {json in
			self.loading = false
			self.waitIndicator.setHidden(true)
			
			if let da = json.array?.last!["data"]["children"]{
				for (_, element) in da.enumerated(){
					
					self.comments[element.1["data"]["id"].string!] = element.1["data"]
					self.idList.append(element.1["data"]["id"].string!)
				}
			} else{
				print("yeah no")
			}
			
			self.commentsTable.setHidden(true)
			self.commentsTable.setNumberOfRows(self.comments.count - 1, withRowType: "commentCell")
			for (index, element) in self.idList.enumerated(){
				_ = [String]()
				if let row = self.commentsTable.rowController(at: index) as? commentController{
					if let stuff = self.comments[element]?.dictionary{
						row.nameLabel.setText(stuff["body"]?.string?.dehtmlify())
						
						if let score = stuff["score"]{
							
							row.scoreLabel.setText("↑ \(String(describing: score.int!)) |")
						}
						
						if let gildedCount = stuff["gilded"]?.int{
							if gildedCount > 0{
								row.gildedIndicator.setHidden(false)
								row.gildedIndicator.setText("\(gildedCount * "•")")
								
							} else{
								row.gildedIndicator.setHidden(true)
							}
						} else
						{
							print("couldn't find gild")
						}
						if let rep = stuff["replies"]{
							if let replyCount = rep["data"]["children"].array{
								if let _ = replyCount.last!["data"]["body"].string{
									row.replies = replyCount.count
									row.replyCount.setText("\(String(describing: replyCount.count)) Replies")
								} else{
									row.replies = replyCount.count - 1
									row.replyCount.setText("\(String(describing: replyCount.count - 1)) Replies")
									
								}
								
							}
							
						}
						row.userLabel.setText(stuff["author"]?.string)
						
						if stuff["author"]?.string! == UserDefaults().string(forKey: "selectedAuthor"){
							row.userLabel.setTextColor(UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0))
						}
						if (stuff["distinguished"]?.null) != nil{
							
						} else{
							if let distin = stuff["distinguished"]?.string{
								if distin == "moderator"{
									row.userLabel.setTextColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0))
									
								} else if distin == "admin"{
									row.userLabel.setTextColor(UIColor(red:0.91, green:0.30, blue:0.24, alpha:1.0))
									
								}
								
								
							}
							
						}
						
						if let newTime = stuff["created_utc"]?.float{
							row.timeLabel.setText(TimeInterval().differenceBetween(newTime))
						}
					} else{
						print("you done stuffed it")
					}
				} else{
					print("helllll no")
				}
			}
			self.commentsTable.setHidden(false)
			WKInterfaceDevice.current().play(.success)
			
			
			
			
		})
		
	}
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		print("Back bitches")
		
		if let sort = UserDefaults.standard.object(forKey: currentPost["title"].string!) as? String{
			UserDefaults.standard.removeObject(forKey: currentPost["title"].string!)
			if let subreddit = currentPost["subreddit"].string, let id = currentPost["id"].string {
				if sort.lowercased() != currentSort{
					print(sort)
					getComments(subreddit: subreddit, id: id, sort: sort)
					currentSort = sort.lowercased()
					self.commentsTable.setNumberOfRows(0, withRowType: "commentCell")
				} else{
					WKInterfaceDevice.current().play(WKHapticType.retry) //Retry, because they may have tapped the wrong sort.
				}
				
			}
		}
	}
	@IBAction func imageTapped(_ sender: Any) {
		print("Heyo")
	}
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		print(ids[Array(comments.keys)[rowIndex]] ?? "found no cell")
		
		
		if (commentsTable.rowController(at: rowIndex) as? commentController) != nil{
			//if row.replies > 0{
			WKInterfaceDevice.current().play(WKHapticType.click)
			self.pushController(withName: "subComment", context: comments[idList[rowIndex]])
			//} else{
			//	WKInterfaceDevice.current().play(WKHapticType.failure)
			//}
		}
		
	}
	@IBAction func upvote() {
		WKInterfaceDevice.current().play(WKHapticType.click)
		if downvoted{
			
			self.downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
		}
		if !upvoted{
			upvoted = true
			self.upvoteButton.setTitleWithColor(title: "↑", color: UIColor(red:0.95, green:0.61, blue:0.07, alpha:1.0))
			self.downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
			print(UserDefaults.standard.object(forKey: "selectedId"))
			reddit.vote(1, id: "\(UserDefaults.standard.object(forKey: "selectedId") as! String)")
			
		} else{
			downvoted = false
			upvoted = false
			self.upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
			reddit.vote(0, id: "\(UserDefaults.standard.object(forKey: "selectedId") as! String)")
		}
		
	}
	@IBAction func downvote() {
		WKInterfaceDevice.current().play(WKHapticType.click)
		if upvoted{
			self.upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
		}
		if !downvoted{
			downvoted = true
			self.downvoteButton.setTitleWithColor(title: "↓", color: UIColor(red:0.16, green:0.50, blue:0.73, alpha:1.0))
			self.upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
			print(UserDefaults.standard.object(forKey: "selectedId"))
			reddit.vote(-1, id: "\(UserDefaults.standard.object(forKey: "selectedId") as! String)")
			
		} else{
			downvoted = false
			upvoted = false
			self.downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
			reddit.vote(0, id: "\(UserDefaults.standard.object(forKey: "selectedId") as! String)")
			
		}
		
	}
	@IBAction func savePost() {
		WKInterfaceDevice.current().play(WKHapticType.click)
		
		if !saved{
			savePostButton.setBackgroundColor(UIColor(red:0.95, green:0.61, blue:0.07, alpha:1.0))
			let id = UserDefaults.standard.object(forKey: "selectedId") as! String
			reddit.save(id: id, type: "post")
			saved = true
		} else{
			savePostButton.setBackgroundColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))
			let id = UserDefaults.standard.object(forKey: "selectedId") as! String
			reddit.save(id: id, type: "post", true)
			saved = false
		}
	}
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	@objc func changeSort(){
		let context = [
			"type": "comment",
			"sorts": ["Best", "Top", "New", "Controversial", "Old"],
			"title": currentPost["title"].string!
			] as [String : Any?]
		self.presentController(withName: "commentSort", context: context)
		
	}
	@IBAction func postComment() {
		if let pro = UserDefaults.standard.object(forKey: "pro") as? Bool{
			if !pro{
				self.presentAlert(withTitle: "Post Comment is a Pro feature", message: "Posting a comment requires the Pro upgrade from the iOS app", preferredStyle: .alert, actions: [WKAlertAction.init(title: "Ok", style: .default, handler: {
					
				})])
				return
			}
		} else{
			self.presentAlert(withTitle: "Post Comment is a Pro feature", message: "Posting a comment requires the Pro upgrade from the iOS app", preferredStyle: .alert, actions: [WKAlertAction.init(title: "Ok", style: .default, handler: {
				
			})])
			return
		}
		presentTextInputController(withSuggestions: ["No"], allowedInputMode:  WKTextInputMode.plain) { (arr: [Any]?) in
			if let arr = arr{
				if let comment = arr.first as? String{
					
					print(self.currentPost["id"].string!)
					self.reddit.post(commentText: comment, parentId: (self.currentPost["id"].string!), completionHandler: {js in
						
						guard let dat = js["json"]["data"]["things"].array else{return}
						guard let first = dat.first else {return}
						
						let postedComment = first["data"]
						
						
						if let author = postedComment["author"].string, let body = postedComment["body"].string{
							
							print("Created")
							let idx = NSIndexSet(index: 0)
							self.commentsTable.insertRows(at: idx as IndexSet, withRowType: "commentCell")
							if let row = self.commentsTable.rowController(at: 0) as? commentController{
								row.scoreLabel.setText("↑ 1 |")
								row.timeLabel.setText("Just Now")
								row.gildedIndicator.setHidden(true)
								row.replyCount.setText("0 Replies")
								row.userLabel.setText(author)
								row.nameLabel.setText(body)
								print("Set")
								self.commentsTable.scrollToRow(at: 0)
							}
						}
						
					})
					
					//TODO: Add row to post without refresh
					
				}
			}
		}
	}
	override func interfaceOffsetDidScrollToBottom() {
		return
		
		if loading {return}
		guard let loadAfter = idList.last else {return}
		print(loadAfter)
		let previousCount = self.comments.count
		loading = true
		reddit.getComments(subreddit: currentSubreddit, id: currentId, sort: currentSort, after: loadAfter, completionHandler: {json in
			self.loading = false
			guard let children = json.array?.last!["data"]["children"] else {return}
			for (_, element) in children.enumerated(){
				
				self.comments[element.1["data"]["id"].string!] = element.1["data"]
				self.idList.append(element.1["data"]["id"].string!)
			}
			
			self.commentsTable.insertRows(at: IndexSet(previousCount ... previousCount + children.count - 1), withRowType: "commentCell")
			for (index, element) in self.idList.dropFirst(previousCount).enumerated(){
				
				if let row = self.commentsTable.rowController(at: index + previousCount) as? commentController{
					if let stuff = self.comments[element]?.dictionary{
						row.nameLabel.setText(stuff["body"]?.string?.dehtmlify())
						if let score = stuff["score"]{
							
							row.scoreLabel.setText("↑ \(String(describing: score.int!)) |")
						}
						
						if let gildedCount = stuff["gilded"]?.int{
							if gildedCount > 0{
								row.gildedIndicator.setHidden(false)
								row.gildedIndicator.setText("\(gildedCount * "•")")
								
							} else{
								row.gildedIndicator.setHidden(true)
							}
						} else
						{
							print("couldn't find gild")
						}
						if let rep = stuff["replies"]{
							if let replyCount = rep["data"]["children"].array{
								if let _ = replyCount.last!["data"]["body"].string{
									row.replies = replyCount.count
									row.replyCount.setText("\(String(describing: replyCount.count)) Replies")
								} else{
									row.replies = replyCount.count - 1
									row.replyCount.setText("\(String(describing: replyCount.count - 1)) Replies")
									
								}
								
							}
							
						}
						row.userLabel.setText(stuff["author"]?.string)
						
						if stuff["author"]?.string! == UserDefaults().string(forKey: "selectedAuthor"){
							row.userLabel.setTextColor(UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0))
						}
						if (stuff["distinguished"]?.null) != nil{
							
						} else{
							if let distin = stuff["distinguished"]?.string{
								if distin == "moderator"{
									row.userLabel.setTextColor(UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0))
									
								} else if distin == "admin"{
									row.userLabel.setTextColor(UIColor(red:0.91, green:0.30, blue:0.24, alpha:1.0))
									
								}
								
								
							}
							
						}
						
						if let newTime = stuff["created_utc"]?.float{
							row.timeLabel.setText(TimeInterval().differenceBetween(newTime))
						}
					} else{
						print("you done stuffed it")
					}
				} else{
					print("helllll no")
				}
			}
			WKInterfaceDevice.current().play(.success)
		})
		
		
	}
	@IBAction func readArticle(_ sender: Any) {
		if !articleContents.isEmpty{
			self.pushController(withName: "articleViewer", context: articleContents)
			
		}
	}
}

extension String{
	func dehtmlify() -> String{
		let html = [
			"&quot;"    : "\"",
			"&amp;"     : "&",
			"&apos;"    : "'",
			"&lt;"      : "<",
			"&gt;"      : ">",
			"&qt;"         : "" //I don't know that &qt; is atm
		]
		var replacement = self
		for (_, element) in html.enumerated(){
			replacement = replacement.replacingOccurrences(of: element.key, with: element.value)
		}
		
		return replacement
		
	}
	
}

extension WKInterfaceButton {
	func setTitleWithColor(title: String, color: UIColor) {
		let attString = NSMutableAttributedString(string: title)
		attString.setAttributes([NSAttributedStringKey.foregroundColor: color], range: NSMakeRange(0, attString.length))
		self.setAttributedTitle(attString)
	}
	
}
