//
//  articleViewer.swift
//  watchapp Extension
//
//  Created by Will Bishop on 20/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import WatchKit

class articleViewer: WKInterfaceController {

	@IBOutlet var articleImage: WKInterfaceImage!
	@IBOutlet var articleTitle: WKInterfaceLabel!
	@IBOutlet var articleContent: WKInterfaceLabel!
	override func awake(withContext context: Any?) {
		if let context = context as? [String: Any]{
			if let title = context["title"] as? String{
				articleTitle.setText(title)
			}
			if let content = context["content"] as? String{
				articleContent.setText(content)
			}
			if let image = context["image"] as? UIImage{
				articleImage.setImage(image)
			}
			
		}
		
	}
}
