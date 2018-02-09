//
//  Reddit.swift
//  watchapp Extension
//
//  Created by Will Bishop on 3/1/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import WatchKit

class RedditAPI{

	var access_token: String
	init(){
		var temp = String()
		if let token = UserDefaults.standard.object(forKey: "access_token") as? String{
			temp = token
		}
		self.access_token = temp
		
		
	}
	func getAccessToken(grantType: String, code: String, completionHandler: @escaping ([String: String]) -> Void){
		///Returns an access token which can be used to perform actions on the users behalf

		var parameters = [
			"grant_type": grantType,
			"redirect_uri": "redditwatch://redirect"
		]
		if grantType == "refresh_token"{
			parameters["refresh_token"] = code
		} else{
			parameters["code"] = code
		}
		Alamofire.request("https://www.reddit.com/api/v1/access_token", method: .post, parameters: parameters)
			.authenticate(user: "uUgh0YyY_k_6ow", password: "")
			.responseJSON(completionHandler: {data in
				if data.response?.statusCode == 200{
					
					UserDefaults.standard.set(true, forKey: "connected")
				}
				if let dat = data.data{
					if let json = try? JSON(data: dat){
						print(json)
						var tokens = [String: String]()
						if grantType != "refresh_token"{
							tokens = ["access_token": json["access_token"].string!, "refresh_token": json["refresh_token"].string!]
							
						} else{
							tokens["acesss_token"] = json["access_token"].string!
						}
						completionHandler(tokens)
						
					}
				}
			})
	}
	func vote(_ direction: Int, id: String, rank: Int = 2,  type: String = "post"){
		///Votes on posts with 3 states, 1 = upvote, 0 = neutral, = -1 = downvote
		let types: [String: String] = ["post": "t3_", "comment": "t1_"]
		let parameters = [
			"dir": direction,
			"id": types[type]! + id,
			"rank": rank
			] as [String : Any]
		let headers = [
			"Authorization": "bearer \(access_token)",
			"User-Agent": "RedditWatch/0.1 by 123icebuggy",
		]
		print(headers)
		let b = Alamofire.request("https://oauth.reddit.com/api/vote", method: .post, parameters: parameters, headers: headers)
			.responseString(completionHandler: {response in
				print(String(describing: response.result.value))
			})
		debugPrint(b)
	}
	func save(id: String, type: String,  _ unsave:Bool = false){
		///Save a post based on it's type and ID
		let types: [String: String] = ["post": "t3_", "comment": "t1_"]
		
		let parameters = [
			"id": types[type]! + id,
			] as [String : Any]
		let headers = [
			"Authorization": "bearer \(access_token)",
			"User-Agent": "RedditWatch/0.1 by 123icebuggy",
			]
		print(parameters)
		print(headers)
		var save = "save"
		if unsave{
			save = "un" + save
		}
		Alamofire.request("https://oauth.reddit.com/api/\(save)", method: .post, parameters: parameters, headers: headers)
			.responseString(completionHandler: {response in
				print(String(describing: response.result.value))
			})
			.response { reponse in
				print("Got \(String(describing: reponse.response?.statusCode))")
		}
	}
	func post(commentText: String, parentId: String, type: String = "post", completionHandler: @escaping (JSON) -> Void){
		///Create a post based on the type of the parent post.
		let headers = [
			"Authorization": "bearer \(access_token)",
			"User-Agent": "RedditWatch/0.1 by 123icebuggy",
		]
		let types = ["post": "t3_", "comment": "t1_"]
		
		print("\(types[type]!	)\(parentId)")
		let parameters = [
			"thing_id": "\(types[type]!)\(parentId)",
			"text": commentText.replacingOccurrences(of: "\n", with: "\n\n"),
			"return_rtjson": false,
			"api_type": "json"
			] as [String : Any]
		
		let b = Alamofire.request("https://oauth.reddit.com/api/comment", method: .post, parameters: parameters, headers: headers)
			.responseJSON{ js in
				if (200 ... 299).contains(js.response!.statusCode){ //Only attempt to process it if we already KNOW it's succesful
					completionHandler(try! JSON(data: js.data!))
				} else{
					#if os(watchOS) //Only try to vibrate if on watchOS
						WKInterfaceDevice.current().play(WKHapticType.failure) //Notify user of failure
					#endif
					
				}
				
			}
			.response { reponse in
				print("Got \(String(describing: reponse.response?.statusCode))")
		}
		debugPrint(b)
	}
	func getSubscriptions(completionHandler: @escaping (JSON?) -> Void){
		let headers = [
			"Authorization": "bearer \(access_token)",
			"User-Agent": "RedditWatch/0.1 by 123icebuggy",
			]
		Alamofire.request("https://oauth.reddit.com/subreddits/mine/subscriber", headers: headers)
			.responseJSON { dat in
				if let data = dat.data{
					completionHandler(try? JSON(data: data))
				} else{
					print("wouldn't let data")
				}
		}
	}
	func getSubreddit(_ subreddit: String = "askreddit", sort: String = "hot", completionHandler: @escaping (JSON) -> Void){
		var home = (subreddit.lowercased() == "home")
		var headers = [
			"Authorization": "bearer \(access_token)",
			"User-Agent": "RedditWatch/0.1 by 123icebuggy",
		]
		var parameters = [String: Any]()
		var url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
		if sort == "top"{
			url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
			parameters["t"] = "all"
			
		} else{
			url = URL(string: "https://www.reddit.com/r/\(subreddit)/\(sort).json")
		}
		if subreddit.lowercased() == "home"{
			url = URL(string: "https://oauth.reddit.com")
		}
		if sort == "top"{
			if home{
				url = URL(string: "https://oauth.reddit.com" + "/\(sort)")
			}
		} else if sort != "hot"{
			if home{
				url = URL(string: "https://oauth.reddit.com" + "/\(sort)")
			}
		}
		if !home{
			headers = [String: String]()
		}
		print(url)
		print(headers)
		print(parameters)
		Alamofire.request(url!, parameters: parameters, headers: headers)
			.responseData { dat in
				if let dat = dat.data{
					if let js = try? JSON(data: dat){
						completionHandler(js)
					}
					
				}
			}
		.responseString(completionHandler: {str in
			print(str.result.value)
		})
	}
}
