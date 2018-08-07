//
//  NavigationController.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//


import UIKit


class NavigationController : UINavigationController {


    override func viewDidLoad() {
        super.viewDidLoad()
        ViewMgr.sharedInstance.rootNavController = self;
    }
}
