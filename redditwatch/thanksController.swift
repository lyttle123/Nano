//
//  thanksController.swift
//  redditwatch
//
//  Created by Will Bishop on 4/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import UIKit

class thanksController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.red

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	override func viewWillDisappear(_ animated: Bool) {
		tabBarController?.tabBar.tintColor = UIColor.flatColors.light.blue
	}
    

    

}
