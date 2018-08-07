//
//  MenuVC.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//


import UIKit


class MenuVC:UIViewController //, FIRHelperDelegate
{
//    func TokenRefreshed() {
//        //
//    }
//
//    func FIRLogUpdate(str: String) {
//       print ("Firebase \(str) Updated!!")
//    }

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var loadText: UILabel!

    var scrollMaxHeight:Double = 0
    var scrollMaxWidth:Double = 0
    var loadedPaidSongs = [""]



    override func viewDidLoad ()
    {
        super.viewDidLoad()
        ViewMgr.sharedInstance.menuVC = self;
        //
        self.scrollView.isScrollEnabled = true
        self.scrollMaxHeight = Double(kItemSize.height)
        self.scrollMaxWidth = 0
        self.showBackgroundImage()

        AppUtils.sharedInstance.checkUserFirebase( {
            (success) in
            print ("checkfirebase done: \(success)")
            self.loadText.isHidden = true
            self.displayItems()
            self.topView.frame = CGRect (x: 0, y: kScreenHeight * 0.02, width: kScreenWidth, height: kScreenHeight * 0.2)
            // Add Listener to Firebase
          //  FIRHelper.sharedInstance.delegate = self
            AppUtils.sharedInstance.addListenerToFirebase()
        })
    }


    override func viewWillAppear(_ animated: Bool) {

    }






    func showBackgroundImage () {
        // update bg image
        let bgImg = UIImage.init(named: AppUtils.sharedInstance.backgroundName)
        self.bgImageView.image = bgImg
    }



    //    func updateArtistNameLabel (){
    //        let artistName = readArtistNameFromPlist(currentAudioIndex)
    //        artistNameLabel.text = artistName
    //    }
    //    func updateAlbumNameLabel(){
    //        let albumName = readAlbumNameFromPlist(currentAudioIndex)
    //        albumNameLabel.text = albumName
    //    }
    //
    //    func updateSongNameLabel(){
    //        let songName = readSongNameFromPlist(currentAudioIndex)
    //        songNameLabel.text = songName
    //    }
    //
    //    func updateAlbumArtwork(){
    //        let artworkName = readArtworkNameFromPlist(currentAudioIndex)
    //        albumArtworkImageView.image = UIImage(named: artworkName)
    //    }


    func displayItems ()
    {

        let audioList = AppUtils.sharedInstance.readFromPlist()
        print (audioList)

        for i in 0..<audioList.count {

            let artworkName = AppUtils.sharedInstance.readArtworkNameFromPlist(audioList, indexNumber: i)
            let loadImage = UIImage.init(named:artworkName)
            //
            let artistName = AppUtils.sharedInstance.readArtistNameFromPlist(audioList, indexNumber: i)
            let detail = Detail.init(text: artistName, idx: i, img: loadImage!)
            let menu = MenuItem.init(frame: CGRect.zero)
            let view = menu.makeUIView(detail: detail)

            // load into scrollView
            let newXpos = (Double(kItemSize.width) + kItemSpacer) * Double(i)
            self.scrollMaxWidth = newXpos + Double(kItemSize.width)
            self.scrollView.addSubview(view)
            self.scrollView.contentSize = CGSize (width:self.scrollMaxWidth, height: self.scrollMaxHeight)
            self.scrollView.sizeToFit()

        }

        // reposition
        self.scrollView.frame = CGRect (x: 0, y: Double((kScreenHeight/2) - (self.scrollMaxHeight/2)), width: kScreenWidth, height: self.scrollMaxHeight)

    }





}

