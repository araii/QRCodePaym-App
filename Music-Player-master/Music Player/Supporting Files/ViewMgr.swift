//
//  ViewMgr.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//


import UIKit




class ViewMgr
{
    // p-singleton
    static let sharedInstance = ViewMgr()

    var currentVC:UIViewController? // *rootViewController

    var rootNavController:NavigationController?  // *rootNavController
    var menuVC:MenuVC? // *menuVC

    let page1VC = AppUtils.sharedInstance.getVC(vcName: "Page1VC", storyboardName: "Main")
    let playerVC = AppUtils.sharedInstance.getVC(vcName: "PlayerViewController", storyboardName: "Main")

    //MARK: Main Methods
    func isViewControllerInStack (whatClass:AnyClass) -> Bool
    {
        if var naviArray = self.rootNavController?.viewControllers {
            for i in 0..<naviArray.count  {
                if (naviArray[i] as AnyObject).isKind(of: whatClass) {
                    return true
                }
            }
        }
        return false
    }





    func gotoPage1 ()
    {
        print (self.currentVC)
//        if (self.currentVC is Page1VC) {
//            return
//        }
        if (self.isViewControllerInStack(whatClass: Page1VC.self) == false) {
            self.rootNavController?.pushViewController (self.page1VC, animated: true)
        } else {
            _ = self.rootNavController?.popToViewController(self.page1VC,animated: false)
        }
    }


    func gotoPlayer ()
    {
         print (self.currentVC)
//        if (self.currentVC is PlayerViewController) {
//            return
//        }
        if (self.isViewControllerInStack(whatClass: PlayerViewController.self) == false) {
            self.rootNavController?.pushViewController (self.playerVC, animated: true)
        }  else {
            _ = self.rootNavController?.popToViewController(self.playerVC,animated: false)
        }
    }

    func gotoPrev ()
    {
         print (self.currentVC)
        self.rootNavController?.popViewController(animated: true)
    }



}
