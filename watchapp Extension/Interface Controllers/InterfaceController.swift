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

class InterfaceController: WKInterfaceController, WCSessionDelegate, customDelegate{
	
	
	
	
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
	
	var loading: Bool{
		set{
			if newValue == true{
				loadingIndicator.setImageNamed("Activity")
				loadingIndicator.startAnimating()
				loadingIndicator.setHidden(false)

			} else{
				loadingIndicator.stopAnimating()
				loadingIndicator.setHidden(true)
			}
		}
		get{
			return self.loading
			
		}
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		invalidateUserActivity()
		loadingIndicator.setHidden(true)

		//		let domain = Bundle.main.bundleIdentifier!
		//		UserDefaults.standard.removePersistentDomain(forName: domain) //Prevent nasty 0 __pthread_kill SIGABRT kill
		//		UserDefaults.standard.synchronize()
		print("we back bitche")
		
		if setup{
			suggestions.insert("home", at: 0)
			suggestions.insert("all", at: 1)
			suggestions.insert("popular", at: 2)
			print("setup")
			if let should = UserDefaults.standard.object(forKey: "shouldLoadDefaultSubreddit") as? Bool{
				if should{
					if let sub = UserDefaults.standard.object(forKey: "defaultSubreddit") as? String{
						print("Setting")
						setupTable(sub, sort: "hot")
					} else{
						print("woulnd't let")
						changeSubreddit()
					}
				} else{
					print("Shouldn't")
					changeSubreddit()
				}
			} else{
				print("not setup")
				
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
		print(timeSince)
		
		if let refresh_token = UserDefaults.standard.object(forKey: "refresh_token") as? String{
			if shouldRefresh{
				UserDefaults.standard.set(Date(), forKey: "lastRefresh")
				print("Haven't refreshed access in atleast 30 mins")
				reddit.getAccessToken(grantType: "refresh_token", code: refresh_token, completionHandler: { result in
					print("Got back \(result)")
					print("Saving \(String(describing: result["acesss_token"]))")
					UserDefaults.standard.set(result["acesss_token"]!, forKey: "access_token")
					self.reddit.access_token = result["acesss_token"]!
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
			UserDefaults.standard.set(responsePhrases, forKey: "phrases")
			phrases = responsePhrases
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
		print("RECEIVED")
		
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
		} else{
			print("WOULDN'T LET")
		}
	}
	func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
		if let responsePhrases = userInfo["phrases"] as? [String]{
			UserDefaults.standard.set(responsePhrases, forKey: "phrases")
			phrases = responsePhrases
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
		var parameters = [String: Any]()
		var url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
		if sort == "top"{
			url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
			parameters["t"] = "all"
			
		} else{
			url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
		}
		if (after?.isEmpty)!{
			names.removeAll()
			images.removeAll()
			ids.removeAll()
			post.removeAll()
			posts.removeAll()
			
		}
		self.redditTable.setNumberOfRows(0, withRowType: "redditCell")
		WKInterfaceDevice.current().play(WKHapticType.start)
		reddit.access_token = UserDefaults.standard.object(forKey: "access_token") as! String
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
			WKInterfaceDevice.current().play(WKHapticType.stop)
			
			
			
		})
		
		//		Alamofire.request(url!, parameters: parameters)
		//			.responseData { (dat) in
		//				let data = dat.data
		//				let error = dat.error
		//				print(String(describing: error))
		//				if (error != nil){
		//					WKInterfaceDevice.current().play(WKHapticType.failure)
		//					self.presentAlert(withTitle: "Error", message: error?.localizedDescription, preferredStyle: .alert, actions: [WKAlertAction.init(title: "Confirm", style: WKAlertActionStyle.default, handler: {
		//						print("Ho")
		//					})])
		//				} else{
		//
		//				}
		//
		//
		
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
			
			
			self.presentTextInputController(withSuggestions: self.suggestions, allowedInputMode:   WKTextInputMode.plain) { (arr: [Any]?) in
				print(arr)
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
		var dir = 0
		if action == "upvote" && !upvoted{
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
	override func interfaceOffsetDidScrollToBottom() {
		let loadAfter = ids.last
		setupTable(currentSubreddit, sort: currentSort, after: loadAfter, currentIndex: self.names.count)
		
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
