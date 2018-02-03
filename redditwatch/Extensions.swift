//
//  Extensions.swift
//  redditwatch
//
//  Created by Will Bishop on 3/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import Foundation
import UIKit

extension UIColor{
	struct flatColors{
		let flatColorRainbow = [light.red, light.orange, light.yellow, light.green, light.blue, light.indigo, light.purple]
		let darkColorRainbow = [ dark.red,  dark.orange,  dark.yellow,  dark.green, dark.blue,  dark.indigo, dark.purple]
		struct light{
			static let red = UIColor(red:0.91, green:0.30, blue:0.24, alpha:1.0)
			static let orange = UIColor(red:0.90, green:0.49, blue:0.13, alpha:1.0)
			static let yellow = UIColor(red:0.95, green:0.77, blue:0.06, alpha:1.0)
			static let green = UIColor(red:0.18, green:0.80, blue:0.44, alpha:1.0)
			static let blue = UIColor(red:0.20, green:0.60, blue:0.86, alpha:1.0)
			static let purple = UIColor(red:0.61, green:0.35, blue:0.71, alpha:1.0)
			static let asphalt = UIColor(red:0.20, green:0.29, blue:0.37, alpha:1.0)
			static let indigo = UIColor(red:0.42, green:0.15, blue:0.98, alpha:1.00)
		}
		struct dark {
			static let red  = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
			static let orange  = UIColor(red:0.83, green:0.33, blue:0.00, alpha:1.0)
			static let yellow  = UIColor(red:0.86, green:0.70, blue:0.05, alpha:1.0)
			static let green  = UIColor(red:0.15, green:0.68, blue:0.38, alpha:1.0)
			static let blue  = UIColor(red:0.16, green:0.50, blue:0.73, alpha:1.0)
			static let purple  = UIColor(red:0.56, green:0.27, blue:0.68, alpha:1.0)
			static let indigo = UIColor(red:0.38, green:0.19, blue:0.88, alpha:1.0)
			static let asphalt  = UIColor(red:0.17, green:0.24, blue:0.31, alpha:1.0)
			
		}
		
	}
	func interpolateRGBColorTo(end: UIColor, fraction: CGFloat) -> UIColor? {
		var f = max(0, fraction)
		f = min(1, fraction)
		
		guard let c1 = self.cgColor.components, let c2 = end.cgColor.components else { return nil }
		
		let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
		let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
		let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
		let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)
		
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}
extension UserDefaults {
	
	func colorForKey(key: String) -> UIColor? {
		var color: UIColor?
		if let colorData = data(forKey: key) {
			color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
		}
		return color
	}
	
	func setColor(color: UIColor?, forKey key: String) {
		var colorData: NSData?
		if let color = color {
			colorData = NSKeyedArchiver.archivedData(withRootObject: color) as NSData
		}
		set(colorData, forKey: key)
	}
	
	
}
