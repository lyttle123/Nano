//
//  InterfaceController.swift
//  watchapp Extension
//
//  Created by Will Bishop on 20/12/17.
//  Copyright © 2017 Will Bishop. All rights reserved.
//

import WatchKit
import Foundation
import SwiftyJSON
import WatchConnectivity
import Alamofire

class InterfaceController: WKInterfaceController, WCSessionDelegate, voteButtonDelegate{
	
	
	
	
	@IBOutlet var redditTable: WKInterfaceTable!
	@IBOutlet var loadingIndicator: WKInterfaceImage!
	var reddit = RedditAPI()
	var upvoted = false
	var downvoted = false
	var posts = [String: [String: Any]]()
	var names = [String]()
	var images = [Int: UIImage]()
	var post = [String: JSON]()
	var ids = [String]()
	var imageDownloadMode = false
	var showSubredditLabels = ["popular", "all", "home"]
	var phrases = [String]()
	var suggestions = UserDefaults.standard.object(forKey: "phrases") as? [String] ?? [String]()
	var wcSession: WCSession?
	var highResImage = UserDefaults.standard.object(forKey: "highResImage") as? Bool ?? false
	var currentSubreddit = String()
	var currentSort = String()
	var setup = UserDefaults.standard.object(forKey: "setup") as? Bool ?? false
	private var _loading: Bool!
	var loading: Bool{
		set{
			if newValue == true{
				loadingIndicator.setImageNamed("Activity")
				loadingIndicator.startAnimating()
				loadingIndicator.setHidden(false)
				_loading = true

			} else{
				_loading = false
				loadingIndicator.stopAnimating()
				loadingIndicator.setHidden(true)
			}
		}
		get{
			return _loading
		}
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		invalidateUserActivity()
		loadingIndicator.setHidden(true)
		if setup{
			suggestions.insert("home", at: 0)
			suggestions.insert("all", at: 1)
			suggestions.insert("popular", at: 2)
			if let should = UserDefaults.standard.object(forKey: "shouldLoadDefaultSubreddit") as? Bool{
				if should{
					if let sub = UserDefaults.standard.object(forKey: "defaultSubreddit") as? String{
						setupTable(sub, sort: "hot")
					} else{
						changeSubreddit()
					}
				} else{
					changeSubreddit()
				}
			} else{
				
				changeSubreddit()
				
			}
			
		}else{
			print("Loading")
			WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("setup", AnyObject.self as AnyObject), ("page2", AnyObject.self as AnyObject), ("tutorial1", AnyObject.self as AnyObject), ("tutorial2", AnyObject.self as AnyObject)])
			
		}
		
		
		
	}
	
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		wcSession = WCSession.default
		wcSession?.delegate = self
		wcSession?.activate()
		
		if let sort = UserDefaults.standard.object(forKey: currentSubreddit + "sort") as? String{
			UserDefaults.standard.removeObject(forKey: currentSubreddit + "sort")
			setupTable(currentSubreddit, sort: sort)
		}
		
		var lastTime = Date()
		var shouldRefresh: Bool
		
		if Platform.isSimulator{
			
			shouldRefresh = true
			
		} else{
			shouldRefresh = false
		}
		
		if let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh") as? Date{
			lastTime = lastRefresh
		} else{
			shouldRefresh = true
		}
		
		let timeSince = Date().timeIntervalSince(lastTime)
		if timeSince > 1800{
			shouldRefresh = true
		}
		
		if let refresh_token = UserDefaults.standard.object(forKey: "refresh_token") as? String{
			if shouldRefresh{
				UserDefaults.standard.set(Date(), forKey: "lastRefresh")
				print("Haven't refreshed access in atleast 30 mins")
				reddit.loading = true
				reddit.getAccessToken(grantType: "refresh_token", code: refresh_token, completionHandler: { result in
					self.reddit.loading = false
					print("Got back \(result)")
					print("Saving \(String(describing: result["access_token"]))")
					UserDefaults.standard.set(result["access_token"]!, forKey: "access_token")
					self.reddit.access_token = result["access_token"]!
				})
			} else{
				print("Not refreshing because refreshed recently")
			}
		} else{
			print("Not setup")
			self.presentController(withName: "setup", context: nil)
		}
		
		
		
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		print(message)
		if let responsePhrases = message["phrases"] as? [String]{
			print("SETTTTTTTING")
			UserDefaults.standard.set(responsePhrases, forKey: "phrases")
			phrases = responsePhrases
			suggestions = responsePhrases
		}
		if let pro = message["purchasedPro"] as? Bool{
			if pro{
				UserDefaults.standard.set(true, forKey: "Pro")
			}
		}
		if let should = message["defaultSubreddit"] as? Bool{
			if should{
				UserDefaults.standard.set(true, forKey: "shouldLoadDefaultSubreddit")
				
			} else{
				UserDefaults.standard.set(false, forKey: "shouldLoadDefaultSubreddit")
			}
		}
		if let defaultSub = message["defaultSubreddit"] as? String{
			
			UserDefaults.standard.set(defaultSub, forKey: "defaultSubreddit")
		}
		if let highres = message["highResImage"] as? Bool{
			UserDefaults.standard.set(highres, forKey: "highResImage")
			highResImage = highres
		}
		
		if let refesh_token = message["refresh_token"] as? String{
			print(refesh_token)
			UserDefaults.standard.set(refesh_token, forKey: "refresh_token")
			if let access_token = message["access_token"] as? String{
				UserDefaults.standard.set(access_token, forKey: "access_token")
				
				UserDefaults.standard.set(true, forKey: "connected")
				print("SHould enable")
				
				if !setup{
					print("Moving away")
					WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("interface", AnyObject.self as AnyObject)])
					self.changeSub()
					self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
						print(error.localizedDescription)
						UserDefaults.standard.set(true, forKey: "setup")
						
					})
					self.setup = true
					
				}
				
				replyHandler(["success": true as AnyObject])
				UserDefaults.standard.set(true, forKey: "setup")
				
			}
		}
	}
	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		if let pro = applicationContext["purchasedPro"] as? Bool{
			if pro{
				UserDefaults.standard.set(true, forKey: "Pro")
			}
		}
	}
	func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
		if let responsePhrases = userInfo["phrases"] as? [String]{
			UserDefaults.standard.set(responsePhrases, forKey: "phrases")
			phrases = responsePhrases
			suggestions = responsePhrases
		}
		if let pro = userInfo["purchasedPro"] as? Bool{
			if pro{
				UserDefaults.standard.set(true, forKey: "Pro")
			}
		}
		if let refesh_token = userInfo["refresh_token"] as? String{
			print(refesh_token)
			UserDefaults.standard.set(refesh_token, forKey: "refresh_token")
			if let access_token = userInfo["access_token"] as? String{
				UserDefaults.standard.set(access_token, forKey: "access_token")
				
				UserDefaults.standard.set(true, forKey: "connected")
				print("SHould enable")
				if !setup{
					print("moving away")
					WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("interface", AnyObject.self as AnyObject)])
					self.changeSub()
					self.wcSession?.sendMessage(["setup":true], replyHandler: nil, errorHandler: { error in
						print(error.localizedDescription)
					})
					UserDefaults.standard.set(true, forKey: "setup")
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
	func setupTable(_ subreddit: String = "askreddit", sort: String = "hot", after: String? = String(), currentIndex: Int = 0){
		
		self.setTitle(subreddit.lowercased())
		
		self.currentSubreddit = subreddit
		self.currentSort = sort
		
		if (after?.isEmpty)!{
			names.removeAll()
			images.removeAll()
			ids.removeAll()
			post.removeAll()
			posts.removeAll()
			
		}
		self.redditTable.setNumberOfRows(0, withRowType: "redditCell")
		WKInterfaceDevice.current().play(WKHapticType.start)
		if let token = UserDefaults.standard.object(forKey: "access_token") as? String{
			reddit.access_token = token
			
		}
		loading = true
		
		reddit.getSubreddit(subreddit, sort: sort, after: after, completionHandler: { json in
			self.loading = false
			let children = json["data"]["children"].array
			guard let child = children else{ return}
			for element in child{
				
				if !(element["data"]["stickied"].bool!){
					self.names.append(element["data"]["title"].string!)
					
					self.post[element["data"]["id"].string!] = element["data"]
					self.ids.append(element["data"]["id"].string!)
					
				}
			}
			if (after?.isEmpty)!{
				print("Hiding")
				self.redditTable.setAlpha(0.0)
				
			}
			self.redditTable.setNumberOfRows(self.names.count, withRowType: "redditCell")
			for (index, _) in self.post.enumerated(){
				if let row = self.redditTable.rowController(at: index ) as? NameRowController{
					if let stuff = self.post[self.ids[index]]
					{
						
						row.nameLabe.setText(stuff["title"].string!.dehtmlify())
						row.id = stuff["id"].string!
						row.delegate = self
						
						if let gildedCount = stuff["gilded"].int{
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
						if let flair = stuff["link_flair_text"].string{
							row.postFlair.setText(flair)
						} else{
							row.postFlair.setHidden(true)
						}
						if let nsfw = stuff["over_18"].bool{
							if nsfw{
								row.nsfwIndicator.setHidden(false)
							} else{
								row.nsfwIndicator.setHidden(true)
							}
						}
						if let subreddit = stuff["subreddit_name_prefixed"].string{
							if self.showSubredditLabels.contains(self.currentSubreddit){
								row.postSubreddit.setText(subreddit)
							} else{
								row.postSubreddit.setHidden(true)
							}
						} else{
							row.postSubreddit.setHidden(true)
						}
						row.postAuthor.setText(stuff["author"].string!)
						row.postCommentCount.setText(String(stuff["num_comments"].int!) + " Comments")
						let score = stuff["score"].int!
						row.postScore.setText("↑ \(String(describing: score)) |")
						if stuff["post_hint"].string != nil{
							if stuff["url"].string!.range(of: "twitter") != nil && (stuff["url"].string!.range(of: "status") != nil){
								print("MATCH: \(stuff["url"].string!)")
								let id = stuff["url"].string!.components(separatedBy: "/").last!
								Twitter().getTweet(tweetId: id, completionHandler: {tweet in
									if let js = tweet{
										row.tweetText.setText(js["text"].string!)
										row.twitterLikes.setText(String(js["favorite_count"].int!) + " Likes")
										row.twitterRetweets.setText(String(describing: js["retweet_count"].int!) +	 " Retweets")
										row.twitterUsername.setText("@" + js["user"]["screen_name"].string!)
										row.twitterDisplayName.setText(js["user"]["name"].string!)
										self.downloadImage(url: js["user"]["profile_image_url_https"].string!, index: 0, completionHandler: { image in
											if let img = image{
												row.twitterPic.setImage(img.circleMasked)
											}
										})
										
									}
									
								})
							} else {
								row.twitterHousing.setHidden(true)
								if let height = stuff["thumbnail_height"].int{
									row.postImage.setHeight(CGFloat(height))
								}
								var url = ""
								//if hint == "image"{
								row.id = stuff["id"].string!
								//row.upvoteButton.set
								if self.highResImage{
									url = stuff["url"].string!
								} else {
									url = stuff["thumbnail"].string! //back to thumbnail, show full image on post view
									if url == "image" || url == "nsfw"{
										url = stuff["url"].string!
									}
								}
								
								if url.range(of: "http") == nil{
									url = "https://" + url
								}
								
								Alamofire.request(url)
									.responseData { data in
										if let data = data.data{
											if let image = UIImage(data: data){
												row.postImage.setImage(image)
												self.images[index] = image
											}
											
										}
										
								}
								
							}
							
							//}
						} else{
							row.twitterHousing.setHidden(true)
						}
						if let newTime = stuff["created_utc"].float{
							
							row.postTime.setText(TimeInterval().differenceBetween(newTime))
						}
						
					}
				}
				
				
				
			}
			self.redditTable.setAlpha(1.0)
			self.redditTable.scrollToRow(at: currentIndex - 1)
			WKInterfaceDevice.current().play(.success)
			
			
			
		})
		
		
	}
	func downloadImage(url: String, index: Int, completionHandler: @escaping (_: UIImage?) -> Void){
		Alamofire.request(url)
			.responseData { data in
				if let data = data.data{
					if let image = UIImage(data: data){
						completionHandler(image)
					}
				}
		}
		
	}
	func changeSub(){
		DispatchQueue.main.async {
			print("CHANGING")
			if self.suggestions[0] != "home"{
				self.suggestions.insert("home", at: 0)
				self.suggestions.insert("all", at: 1)
				self.suggestions.insert("popular", at: 2)
			}
			self.presentTextInputController(withSuggestions: self.suggestions, allowedInputMode:   WKTextInputMode.plain) { (arr: [Any]?) in
				print(arr ?? "Failed")
				if let input = arr?.first as? String{
					self.setupTable(input.lowercased().replacingOccurrences(of: " ", with: ""))
				} else{
					print(self.currentSubreddit)
					if self.currentSubreddit.isEmpty{
						WKInterfaceDevice.current().play(WKHapticType.failure)
						self.changeSubreddit()
						
					}
				}
			}
			
		}
		
	}
	
	@IBAction func changeSubreddit() {
		changeSub()
	}
	@IBAction func changeSort() {
		
		let context = [
			"type": "subreddit",
			"sorts": ["Hot", "New", "Rising", "Controversial", "Top", "Gilded"],
			"title": nil,
			"subreddit": currentSubreddit
			] as [String : Any?]
		self.presentController(withName: "commentSort", context: context)
		
		
	}
	
	
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		WKInterfaceDevice.current().play(WKHapticType.click)
		if let row = redditTable.rowController(at: rowIndex) as? NameRowController{
			row.nameLabe.setTextColor(UIColor.lightGray)
			if images[rowIndex] != nil{
				print("Should attach image")
				UserDefaults.standard.set(true, forKey: "shouldLoadImage")
				UserDefaults.standard.set(ids[rowIndex], forKey: "selectedId")
				UserDefaults.standard.set(UIImagePNGRepresentation(images[rowIndex]!), forKey: "selectedThumbnail")
				self.pushController(withName: "lorem", context: post[ids[rowIndex]])
			} else{
				UserDefaults.standard.set(false, forKey: "shouldLoadImage")
				UserDefaults.standard.set(ids[rowIndex], forKey: "selectedId")
				self.pushController(withName: "lorem", context: post[ids[rowIndex]])
			}
		}
	}
	func didSelect(upvoteButton: WKInterfaceButton, downvoteButton: WKInterfaceButton, onCellWith id: String, action: String) {
		print(id)
		WKInterfaceDevice.current().play(.click)

		var dir = 0
		if action == "upvote" && !upvoted{
			WKInterfaceDevice.current().play(.click)
			print("Upvoting")
			dir = 1
			upvoted = true
			downvoted = false
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor(red:0.95, green:0.61, blue:0.07, alpha:1.0))
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
			
		}else if action == "upvote" && upvoted{
			print("Removing Upvote")
			upvoted = false
			downvoted = false
			dir = 0
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
			
		} else if action == "downvote" && !downvoted{
			print("Downvoting")
			downvoted = true
			upvoted = false
			dir = -1
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor(red:0.16, green:0.50, blue:0.73, alpha:1.0))
			upvoteButton.setTitleWithColor(title: "↑", color: UIColor.white)
			
		} else if action == "downvote" && downvoted{
			print("Removing downvote")
			downvoted = false
			upvoted = false
			downvoteButton.setTitleWithColor(title: "↓", color: UIColor.white)
		}
		
		reddit.vote(dir, id: id)
	}
	@IBAction func refreshSub() {
		self.setupTable(currentSubreddit, sort: currentSort)
	}
	override func interfaceOffsetDidScrollToBottom() {
		if loading {return} //If we're already loading posts, don't try again
		WKInterfaceDevice.current().play(.click)

		print("LOADING MORE")
		let loadAfter = ids.last
		let previousCount = self.post.count
		loading = true
		reddit.getSubreddit(currentSubreddit, sort: currentSort, after: loadAfter, completionHandler: {json in
			WKInterfaceDevice.current().play(.success)

			self.loading = false
			let children = json["data"]["children"].array
			self.redditTable.insertRows(at: IndexSet(self.names.count ... self.names.count + (children?.count)! - 1), withRowType: "redditCell") //From the current number of posts to the current number of posts + the number of new posts minus one because arrays start at zero
			guard let child = children else{ return}
			
			for element in child{
				
				if !(element["data"]["stickied"].bool!){
					self.names.append(element["data"]["title"].string!)
					self.post[element["data"]["id"].string!] = element["data"]
					self.ids.append(element["data"]["id"].string!)
					
				}
				
			}
			print(child.count)
			for (index, _) in self.post.dropFirst(previousCount).enumerated(){
				if let row = self.redditTable.rowController(at: index + self.post.count - 25) as? NameRowController{
					if let stuff = self.post[self.ids[index + self.post.count - 25]]
					{
						
						row.nameLabe.setText(stuff["title"].string!.dehtmlify())
						row.id = stuff["id"].string!
						row.delegate = self
						
						if let gildedCount = stuff["gilded"].int{
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
						if let flair = stuff["link_flair_text"].string{
							row.postFlair.setText(flair)
						} else{
							row.postFlair.setHidden(true)
						}
						if let nsfw = stuff["over_18"].bool{
							if nsfw{
								row.nsfwIndicator.setHidden(false)
							} else{
								row.nsfwIndicator.setHidden(true)
							}
						}
						if let subreddit = stuff["subreddit_name_prefixed"].string{
							if self.showSubredditLabels.contains(self.currentSubreddit){
								row.postSubreddit.setText(subreddit)
							} else{
								row.postSubreddit.setHidden(true)
							}
						} else{
							row.postSubreddit.setHidden(true)
						}
						row.postAuthor.setText(stuff["author"].string!)
						row.postCommentCount.setText(String(stuff["num_comments"].int!) + " Comments")
						let score = stuff["score"].int!
						row.postScore.setText("↑ \(String(describing: score)) |")
						if stuff["post_hint"].string != nil{
							if stuff["url"].string!.range(of: "twitter") != nil && (stuff["url"].string!.range(of: "status") != nil){
								print("MATCH: \(stuff["url"].string!)")
								let id = stuff["url"].string!.components(separatedBy: "/").last!
								Twitter().getTweet(tweetId: id, completionHandler: {tweet in
									if let js = tweet{
										row.tweetText.setText(js["text"].string!)
										row.twitterLikes.setText(String(js["favorite_count"].int!) + " Likes")
										row.twitterRetweets.setText(String(describing: js["retweet_count"].int!) +	 " Retweets")
										row.twitterUsername.setText("@" + js["user"]["screen_name"].string!)
										row.twitterDisplayName.setText(js["user"]["name"].string!)
										self.downloadImage(url: js["user"]["profile_image_url_https"].string!, index: 0, completionHandler: { image in
											if let img = image{
												row.twitterPic.setImage(img.circleMasked)
											}
										})
										
									}
									
								})
							} else {
								row.twitterHousing.setHidden(true)
								if let height = stuff["thumbnail_height"].int{
									row.postImage.setHeight(CGFloat(height))
								}
								var url = ""
								//if hint == "image"{
								row.id = stuff["id"].string!
								//row.upvoteButton.set
								if self.highResImage{
									url = stuff["url"].string!
								} else {
									url = stuff["thumbnail"].string! //back to thumbnail, show full image on post view
									if url == "image" || url == "nsfw"{
										url = stuff["url"].string!
									}
								}
								
								if url.range(of: "http") == nil{
									url = "https://" + url
								}
								
								Alamofire.request(url)
									.responseData { data in
										if let data = data.data{
											if let image = UIImage(data: data){
												row.postImage.setImage(image)
												self.images[index + (children?.count)!] = image
											}
											
										}
										
								}
								
							}
							
							//}
						} else{
							row.twitterHousing.setHidden(true)
						}
						if let newTime = stuff["created_utc"].float{
							
							row.postTime.setText(TimeInterval().differenceBetween(newTime))
						}
						
					}
				}
			}
			
		})
//		setupTable(currentSubreddit, sort: currentSort, after: loadAfter, currentIndex: self.names.count)
		
	}
	
	
}
extension String{
	
	static func *(left: Int, right: String) -> String{
		var input = ""
		for _ in 1 ... left{
			input = input + right
		}
		return input
	}
}
extension UIImage {
	var isPortrait:  Bool    { return size.height > size.width }
	var isLandscape: Bool    { return size.width > size.height }
	var breadth:     CGFloat { return min(size.width, size.height) }
	var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
	var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
	var circleMasked: UIImage? {
		UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
		defer { UIGraphicsEndImageContext() }
		guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
		UIBezierPath(ovalIn: breadthRect).addClip()
		UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
		return UIGraphicsGetImageFromCurrentImageContext()
	}
}
