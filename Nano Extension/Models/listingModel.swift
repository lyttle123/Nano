//
//  listingModel.swift
//  watchapp Extension
//
//  Created by Will Bishop on 10/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   guard let welcome = try Welcome(json) else { ... }

import Foundation

struct Welcome: Codable {
	let kind: String
	let data: WelcomeData
}

struct WelcomeData: Codable {
	let after: String
	let dist: Int
	let modhash, whitelistStatus: String
	let children: [Child]
	let before: JSONNull?
	
	enum CodingKeys: String, CodingKey {
		case after, dist, modhash
		case whitelistStatus = "whitelist_status"
		case children, before
	}
}

struct Child: Codable {
	let kind: String
	let data: ChildData
}

struct ChildData: Codable {
	let domain: String
	let approvedAtUTC, modReasonBy, bannedBy, numReports: JSONNull?
	let subredditID: String
	let thumbnailWidth: Int?
	let subreddit: String
	let selftextHTML: String?
	let selftext: String
	let likes, suggestedSort: JSONNull?
	let userReports: [JSONAny]
	let secureMedia: Media?
	let isRedditMediaDomain: Bool
	let linkFlairText: String?
	let id: String
	let bannedAtUTC, modReasonTitle, viewCount: JSONNull?
	let archived, clicked: Bool
	let mediaEmbed: MediaEmbed
	let reportReasons: JSONNull?
	let author: String
	let numCrossposts: Int
	let saved: Bool
	let modReports: [JSONAny]
	let canModPost, isCrosspostable, pinned: Bool
	let score: Int
	let approvedBy: JSONNull?
	let over18, hidden: Bool
	let thumbnail: String
	let edited: Edited
	let linkFlairCSSClass, authorFlairCSSClass: String?
	let contestMode: Bool
	let gilded, downs: Int
	let brandSafe: Bool
	let secureMediaEmbed: MediaEmbed
	let removalReason: JSONNull?
	let authorFlairText: String?
	let stickied, canGild: Bool
	let thumbnailHeight: Int?
	let parentWhitelistStatus, name: String
	let spoiler: Bool
	let permalink, subredditType: String
	let locked, hideScore: Bool
	let created: Int
	let url, whitelistStatus: String
	let quarantine: Bool
	let title: String
	let createdUTC: Int
	let subredditNamePrefixed: String
	let ups: Int
	let media: Media?
	let numComments: Int
	let isSelf, visited: Bool
	let modNote: JSONNull?
	let isVideo: Bool
	let distinguished: String?
	let preview: Preview?
	let postHint: String?
	
	enum CodingKeys: String, CodingKey {
		case domain
		case approvedAtUTC = "approved_at_utc"
		case modReasonBy = "mod_reason_by"
		case bannedBy = "banned_by"
		case numReports = "num_reports"
		case subredditID = "subreddit_id"
		case thumbnailWidth = "thumbnail_width"
		case subreddit
		case selftextHTML = "selftext_html"
		case selftext, likes
		case suggestedSort = "suggested_sort"
		case userReports = "user_reports"
		case secureMedia = "secure_media"
		case isRedditMediaDomain = "is_reddit_media_domain"
		case linkFlairText = "link_flair_text"
		case id
		case bannedAtUTC = "banned_at_utc"
		case modReasonTitle = "mod_reason_title"
		case viewCount = "view_count"
		case archived, clicked
		case mediaEmbed = "media_embed"
		case reportReasons = "report_reasons"
		case author
		case numCrossposts = "num_crossposts"
		case saved
		case modReports = "mod_reports"
		case canModPost = "can_mod_post"
		case isCrosspostable = "is_crosspostable"
		case pinned, score
		case approvedBy = "approved_by"
		case over18 = "over_18"
		case hidden, thumbnail, edited
		case linkFlairCSSClass = "link_flair_css_class"
		case authorFlairCSSClass = "author_flair_css_class"
		case contestMode = "contest_mode"
		case gilded, downs
		case brandSafe = "brand_safe"
		case secureMediaEmbed = "secure_media_embed"
		case removalReason = "removal_reason"
		case authorFlairText = "author_flair_text"
		case stickied
		case canGild = "can_gild"
		case thumbnailHeight = "thumbnail_height"
		case parentWhitelistStatus = "parent_whitelist_status"
		case name, spoiler, permalink
		case subredditType = "subreddit_type"
		case locked
		case hideScore = "hide_score"
		case created, url
		case whitelistStatus = "whitelist_status"
		case quarantine, title
		case createdUTC = "created_utc"
		case subredditNamePrefixed = "subreddit_name_prefixed"
		case ups, media
		case numComments = "num_comments"
		case isSelf = "is_self"
		case visited
		case modNote = "mod_note"
		case isVideo = "is_video"
		case distinguished, preview
		case postHint = "post_hint"
	}
}

enum Edited: Codable {
	case bool(Bool)
	case integer(Int)
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let x = try? container.decode(Bool.self) {
			self = .bool(x)
			return
		}
		if let x = try? container.decode(Int.self) {
			self = .integer(x)
			return
		}
		throw DecodingError.typeMismatch(Edited.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Edited"))
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .bool(let x):
			try container.encode(x)
		case .integer(let x):
			try container.encode(x)
		}
	}
}

struct Media: Codable {
	let redditVideo: RedditVideo
	
	enum CodingKeys: String, CodingKey {
		case redditVideo = "reddit_video"
	}
}

struct RedditVideo: Codable {
	let fallbackURL: String
	let height, width: Int
	let scrubberMediaURL, dashURL: String
	let duration: Int
	let hlsURL: String
	let isGIF: Bool
	let transcodingStatus: String
	
	enum CodingKeys: String, CodingKey {
		case fallbackURL = "fallback_url"
		case height, width
		case scrubberMediaURL = "scrubber_media_url"
		case dashURL = "dash_url"
		case duration
		case hlsURL = "hls_url"
		case isGIF = "is_gif"
		case transcodingStatus = "transcoding_status"
	}
}

struct MediaEmbed: Codable {
}

struct Preview: Codable {
	let images: [Image]
	let enabled: Bool
}

struct Image: Codable {
	let source: Resolution
	let resolutions: [Resolution]
	let variants: MediaEmbed
	let id: String
}

struct Resolution: Codable {
	let url: String
	let width, height: Int
}

// MARK: Convenience initializers

extension Welcome {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Welcome.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension WelcomeData {
	init(data: Data) throws {
		self = try JSONDecoder().decode(WelcomeData.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension Child {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Child.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension ChildData {
	init(data: Data) throws {
		self = try JSONDecoder().decode(ChildData.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension Media {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Media.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension RedditVideo {
	init(data: Data) throws {
		self = try JSONDecoder().decode(RedditVideo.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension MediaEmbed {
	init(data: Data) throws {
		self = try JSONDecoder().decode(MediaEmbed.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension Preview {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Preview.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension Image {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Image.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

extension Resolution {
	init(data: Data) throws {
		self = try JSONDecoder().decode(Resolution.self, from: data)
	}
	
	init?(_ json: String, using encoding: String.Encoding = .utf8) throws {
		guard let data = json.data(using: encoding) else { return nil }
		try self.init(data: data)
	}
	
	init?(fromURL url: String) throws {
		guard let url = URL(string: url) else { return nil }
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	func jsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	
	func jsonString() throws -> String? {
		return String(data: try self.jsonData(), encoding: .utf8)
	}
}

// MARK: Encode/decode helpers

class JSONNull: Codable {
	public init() {}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if !container.decodeNil() {
			throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encodeNil()
	}
}

class JSONCodingKey: CodingKey {
	let key: String
	
	required init?(intValue: Int) {
		return nil
	}
	
	required init?(stringValue: String) {
		key = stringValue
	}
	
	var intValue: Int? {
		return nil
	}
	
	var stringValue: String {
		return key
	}
}

class JSONAny: Codable {
	public let value: Any
	
	static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
		let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
		return DecodingError.typeMismatch(JSONAny.self, context)
	}
	
	static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
		let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
		return EncodingError.invalidValue(value, context)
	}
	
	static func decode(from container: SingleValueDecodingContainer) throws -> Any {
		if let value = try? container.decode(Bool.self) {
			return value
		}
		if let value = try? container.decode(Int64.self) {
			return value
		}
		if let value = try? container.decode(Double.self) {
			return value
		}
		if let value = try? container.decode(String.self) {
			return value
		}
		if container.decodeNil() {
			return JSONNull()
		}
		throw decodingError(forCodingPath: container.codingPath)
	}
	
	static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
		if let value = try? container.decode(Bool.self) {
			return value
		}
		if let value = try? container.decode(Int64.self) {
			return value
		}
		if let value = try? container.decode(Double.self) {
			return value
		}
		if let value = try? container.decode(String.self) {
			return value
		}
		if let value = try? container.decodeNil() {
			if value {
				return JSONNull()
			}
		}
		if var container = try? container.nestedUnkeyedContainer() {
			return try decodeArray(from: &container)
		}
		if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
			return try decodeDictionary(from: &container)
		}
		throw decodingError(forCodingPath: container.codingPath)
	}
	
	static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
		if let value = try? container.decode(Bool.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(Int64.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(Double.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(String.self, forKey: key) {
			return value
		}
		if let value = try? container.decodeNil(forKey: key) {
			if value {
				return JSONNull()
			}
		}
		if var container = try? container.nestedUnkeyedContainer(forKey: key) {
			return try decodeArray(from: &container)
		}
		if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
			return try decodeDictionary(from: &container)
		}
		throw decodingError(forCodingPath: container.codingPath)
	}
	
	static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
		var arr: [Any] = []
		while !container.isAtEnd {
			let value = try decode(from: &container)
			arr.append(value)
		}
		return arr
	}
	
	static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
		var dict = [String: Any]()
		for key in container.allKeys {
			let value = try decode(from: &container, forKey: key)
			dict[key.stringValue] = value
		}
		return dict
	}
	
	static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
		for value in array {
			if let value = value as? Bool {
				try container.encode(value)
			} else if let value = value as? Int64 {
				try container.encode(value)
			} else if let value = value as? Double {
				try container.encode(value)
			} else if let value = value as? String {
				try container.encode(value)
			} else if value is JSONNull {
				try container.encodeNil()
			} else if let value = value as? [Any] {
				var container = container.nestedUnkeyedContainer()
				try encode(to: &container, array: value)
			} else if let value = value as? [String: Any] {
				var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
				try encode(to: &container, dictionary: value)
			} else {
				throw encodingError(forValue: value, codingPath: container.codingPath)
			}
		}
	}
	
	static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
		for (key, value) in dictionary {
			let key = JSONCodingKey(stringValue: key)!
			if let value = value as? Bool {
				try container.encode(value, forKey: key)
			} else if let value = value as? Int64 {
				try container.encode(value, forKey: key)
			} else if let value = value as? Double {
				try container.encode(value, forKey: key)
			} else if let value = value as? String {
				try container.encode(value, forKey: key)
			} else if value is JSONNull {
				try container.encodeNil(forKey: key)
			} else if let value = value as? [Any] {
				var container = container.nestedUnkeyedContainer(forKey: key)
				try encode(to: &container, array: value)
			} else if let value = value as? [String: Any] {
				var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
				try encode(to: &container, dictionary: value)
			} else {
				throw encodingError(forValue: value, codingPath: container.codingPath)
			}
		}
	}
	
	static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
		if let value = value as? Bool {
			try container.encode(value)
		} else if let value = value as? Int64 {
			try container.encode(value)
		} else if let value = value as? Double {
			try container.encode(value)
		} else if let value = value as? String {
			try container.encode(value)
		} else if value is JSONNull {
			try container.encodeNil()
		} else {
			throw encodingError(forValue: value, codingPath: container.codingPath)
		}
	}
	
	public required init(from decoder: Decoder) throws {
		if var arrayContainer = try? decoder.unkeyedContainer() {
			self.value = try JSONAny.decodeArray(from: &arrayContainer)
		} else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
			self.value = try JSONAny.decodeDictionary(from: &container)
		} else {
			let container = try decoder.singleValueContainer()
			self.value = try JSONAny.decode(from: container)
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		if let arr = self.value as? [Any] {
			var container = encoder.unkeyedContainer()
			try JSONAny.encode(to: &container, array: arr)
		} else if let dict = self.value as? [String: Any] {
			var container = encoder.container(keyedBy: JSONCodingKey.self)
			try JSONAny.encode(to: &container, dictionary: dict)
		} else {
			var container = encoder.singleValueContainer()
			try JSONAny.encode(to: &container, value: self.value)
		}
	}
}

