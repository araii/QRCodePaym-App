//
//  MenuItem.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//

import UIKit


struct Detail
{
    let text:String
    let idx:Int
    let img:UIImage?
    let items = [String]()

    init (text:String, idx:Int, img:UIImage?) {
        self.text = text
        self.idx = idx
        self.img = img
    }
}
let kScalef = Double(kScreenWidth * 0.3)

let kItemSize:CGSize = CGSize.init(width: kScalef, height: kScalef)
let kItemSpacer:Double = 50
let kImgSize:CGSize = CGSize.init(width: kScalef-20, height: kScalef-20)




class MenuItem:UIView
{

    var loadImage:UIImage?
    var detail:Detail = Detail.init(text: "", idx: -1, img:nil)


    @objc func tapGestureRecognized (_ view:UIView)
    {
        AppUtils.sharedInstance.currentArtistIndex = self.detail.idx
        ViewMgr.sharedInstance.gotoPage1()
    }


    func makeUIView (detail:Detail) -> UIView
    {
        self.detail = detail

        // make new UIView..
        print ("estimate:\(kScalef) vs screenwidth:\(kScreenWidth)")

        let newXpos = (Double(kItemSize.width) + kItemSpacer) * Double(detail.idx)
        self.frame = CGRect (x:newXpos, y:0,
                             width: Double(kItemSize.width),
                             height: Double(kItemSize.height) )
        // add gestureRecogn
        let tap = UITapGestureRecognizer(target:self,
                                         action:#selector(tapGestureRecognized(_:)))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
        // handle shadow
        let shadowView = handleShadow()
        self.addSubview(shadowView)
        // handle image load..
        let imgView = handleImage()
        imgView.setRounded()
        self.addSubview(imgView)

        // handle text load..
        let textview = handleTitle()
        self.addSubview(textview)

        // resize only after addsubview..
        var frame = textview.frame
        frame.size.height = textview.contentSize.height
        textview.frame = frame

        return self
    }



    func handleTitle () -> UITextView {
        let t = UITextView.init(frame: CGRect (x: 0,
                                               y: Double(kImgSize.height) + 10,
                                               width: Double(kItemSize.width),
                                               height: 50))
        t.backgroundColor = UIColor.clear
        t.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        t.textColor = UIColor.black
        t.text = detail.text 
        t.textAlignment = NSTextAlignment.center
        return t
    }


    func handleImage () -> UIImageView {
        let imgV = UIImageView.init(frame: CGRect (x: Double((kItemSize.width-kImgSize.width)/2), y: 0,
                                                   width: Double(kImgSize.width),
                                                   height: Double(kImgSize.height) ))
        imgV.image = detail.img
        return imgV
    }

    func handleShadow () -> UIImageView {
        let imgV = UIImageView.init(frame: CGRect (x:Double((kItemSize.width-kImgSize.width)/2), y: 0,
                                                  width: Double(kImgSize.width)+20,
                                                  height: Double(kImgSize.height)+20 ))
        imgV.image = UIImage.init(named: "shadow.png")
        return imgV
    }



//    cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
    //        cell.textLabel?.textColor = UIColor.white
    //        cell.textLabel?.text = songName
    //
    //        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
    //        cell.detailTextLabel?.textColor = UIColor.white
    //        cell.detailTextLabel?.text = albumName

}
