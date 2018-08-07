//
//  Page1VC.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//


import UIKit
//import Foundation



class Page1VC:UIViewController, UITableViewDelegate, UITableViewDataSource, FIRHelperDelegate
{


    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var pageTitle: UILabel!

    @IBOutlet weak var artistView: UIView!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var shadowImageView: UIImageView!
    
    @IBOutlet var tableViewContainer : UIView!
    @IBOutlet var tableView : UITableView!
    @IBOutlet weak var qrcodeView: UIView!
    @IBOutlet weak var qrcodeText: UILabel!
    @IBOutlet weak var qrcodeViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topQRView: UIView!

    var audioList:NSArray = []
    var songList:NSArray = []



    override func viewDidLoad () {
        // run once
        audioList = AppUtils.sharedInstance.readFromPlist()
        updateBackgroundImage()
        //
        self.topView.frame = CGRect (x: 0, y:kScreenHeight * 0.02,
                                     width: kScreenWidth, height: kScreenHeight * 0.2)
        self.topQRView.frame = CGRect (x: 0, y:kScreenHeight * 0.02,
                                       width: kScreenWidth, height: kScreenHeight * 0.3)
    }


    override func viewWillAppear(_ animated: Bool) {
        ViewMgr.sharedInstance.currentVC = self
        //
        self.blurView.isHidden = true
        self.qrcodeViewTopContraint.constant = 1000.0
        self.qrcodeView.layoutIfNeeded()

        // update song list
        songList = AppUtils.sharedInstance.readSongListFromPlist(audioList, indexNumber: AppUtils.sharedInstance.currentArtistIndex)

        updateArtwork()
        updateArtistName()
        tableView.reloadData()
    }


    // Table View Part of the code. Displays Song name and Artist Name
    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {

        var albumNameDict = NSDictionary();
        albumNameDict = audioList.object(at: AppUtils.sharedInstance.currentArtistIndex) as! NSDictionary

        let albumName = albumNameDict.value(forKey: "albumName") as! String
        let songName = self.songList [indexPath.row] as! String
        // Song Name
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.text = songName
        // Album Name
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.black
        cell.detailTextLabel?.text = albumName
        return cell
    }

    
    // ===== Preview Buttons ======
    func makePreviewButton (xpos:Double, ypos:Double) -> UIButton {
        let btn = UIButton.init(frame: CGRect (x:xpos, y:ypos ,
                                               width: 30,
                                               height: 30))
        btn.setImage(UIImage.init(named: "play.png"), for: UIControlState.normal)
        return btn
    }

    @objc func buttonPress (_ sender:UIButton) {
        // TODO: ADD preview method...
        print (" preview song number: \(sender.tag)")
    }
    //  ===========================


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(_ tableView: UITableView,willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath){
        tableView.backgroundColor = UIColor.clear

        let backgroundView = UIView(frame: CGRect.zero)
        backgroundView.backgroundColor = UIColor.clear
        cell.backgroundView = backgroundView
        cell.backgroundColor = UIColor.clear
    }


    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        print (indexPath.row)
        AppUtils.sharedInstance.currentSongIndex = indexPath.row
        // check if song has been 'paid'
        if (AppUtils.sharedInstance.checkCurrentSongPayment()) {
            print ("paid song")
            ViewMgr.sharedInstance.gotoPlayer()
        } else {
            animateQRViewToScreen()
        }
    }



    // MARK: QRCodeView Methods...
    func animateQRViewToScreen() {
        // FirHelper delegate
        FIRHelper.sharedInstance.delegate = self
        //
        self.blurView.isHidden = false
        self.qrcodeViewTopContraint.constant = 0.0
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: UIViewAnimationOptions.curveEaseIn, animations:  {
            self.qrcodeView.layoutIfNeeded()
        }, completion: { (bool) in

            self.displayQRCode()
            self.qrcodeText.text = "'\(self.songList[AppUtils.sharedInstance.currentSongIndex])'"
            self.qrcodeText.textAlignment = .center
        })
    }

    func animateQRViewToOffScreen(){
        // FirHelper delegate
        FIRHelper.sharedInstance.delegate = nil
        //
        self.qrcodeViewTopContraint.constant = 1000.0
        UIView.animate(withDuration: 0.20, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.qrcodeView.layoutIfNeeded()
        }, completion: {
            (value: Bool) in
            self.blurView.isHidden = true
        })
    }

    func displayQRCode() {
        let message = self.getQRCodeMessage()
        print (message)
        let image = AppUtils.sharedInstance.generateQRCode(from: message)
        let imgView = UIImageView.init(frame: CGRect (x: Double(self.qrcodeView.center.x - (kImgSize.width/2)),
                                                      y: Double(self.qrcodeView.center.y - (kImgSize.height/3.5)),
                                                      width: Double(kImgSize.width),
                                                      height: Double(kImgSize.height) ))
        imgView.image = image
        self.qrcodeView.addSubview(imgView)
    }





    // MARK: Update UI Methods
    func updateBackgroundImage () {
        let bgImg = UIImage.init(named: AppUtils.sharedInstance.backgroundName)
        self.bgImageView.image = bgImg
    }

    func updateArtwork() {
        let imgName = AppUtils.sharedInstance.readArtworkNameFromPlist(audioList, indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        // reSize & rePosition
        let xpos = (kScreenWidth * 0.25) - (kScalef/2)
        let ypos = (kScreenHeight/2) - Double(self.artistView.frame.height/2) // estimate with textfield height
        self.artistImageView.frame = CGRect(x: xpos, y: ypos, width: kScalef, height: kScalef)
        self.shadowImageView.frame = CGRect(x: xpos, y: ypos, width: kScalef+20, height: kScalef+20)
        self.artistImageView.image = UIImage.init(named: imgName)
        self.artistImageView.setRounded()
    }

    func updateArtistName() {
        let artistName = AppUtils.sharedInstance.readArtistNameFromPlist(audioList, indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        self.artistName.text = artistName
        self.artistName.sizeToFit()
        // reSize & rePosition
        let xpos = Double(kScreenWidth * 0.25) - Double(self.artistName.frame.width/2)
        let ypos = Double(self.artistImageView.frame.minY + self.artistImageView.frame.height)+20
        self.artistName.frame = CGRect (x: xpos,
                                        y: ypos,
                                        width: Double(self.artistName.frame.width),
                                        height: Double(self.artistName.frame.height))
    }


    // MARK: UI Buttons
    @IBAction func onPressBack(_ sender: Any) {
        ViewMgr.sharedInstance.gotoPrev()
    }

    @IBAction func onPressClose(_ sender: Any) {
        animateQRViewToOffScreen()
    }


    @IBAction func onPressPaid(_ sender: Any) {
        self.updatePaidSongsToDB()
    }


    // MARK: Song Payment Methods..
    func getQRCodeMessage() -> String {
        let currentSong = AppUtils.sharedInstance.getCurrentSongName()
        return "\(kPaymentURL)\(currentSong)_\(UserDefaultGetUUID())"
    }


    func updatePaidSongsToDB () {
        let newstring = self.getQRCodeMessage()
        let data = newstring.stringByRemovingPrefixSymbols
        // update paid songs
        AppUtils.sharedInstance.loadedPaidSongs.append(data[1])
        let postDict = ["PaidSongs":AppUtils.sharedInstance.loadedPaidSongs]
        print ("upated paidSongs \(postDict)")
        FIRHelper.sharedInstance.replaceDataToDbname(dbname: "QRCodePaym",
                                                     withId: data[0],
                                                     data: postDict as NSDictionary,
                                                     returnBlock:
            {
                (success) in
                print (success)
                ViewMgr.sharedInstance.gotoPlayer()
        })
    }


    // MARK: FirHelper Delegates..
    func TokenRefreshed() {}

    func FIRLogUpdate(str: String) {
        print ("update")
        AppUtils.sharedInstance.checkUserFirebase { (done) in
            print ("updated paidsongs \(AppUtils.sharedInstance.loadedPaidSongs)")
            if (AppUtils.sharedInstance.checkCurrentSongPayment()) {
                print ("paid song")
                ViewMgr.sharedInstance.gotoPlayer()
            } else {
                self.animateQRViewToScreen()
            }
        }
    }



}
