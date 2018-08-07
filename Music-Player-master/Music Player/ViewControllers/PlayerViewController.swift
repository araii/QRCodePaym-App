//
//  ViewController.swift
//  Music Player
//
//  Created by Arai on 25/5/18.
//  Credit - bpolat@live.com. All rights reserved.


import UIKit
import AVFoundation
import MediaPlayer



class PlayerViewController: UIViewController, AVAudioPlayerDelegate {


    var audioPlayer:AVAudioPlayer! = nil
    var currentAudio = ""
    var currentAudioPath:URL!
    var currentSongIndex = 0
    var timer:Timer!
    var audioLength = 0.0
    var toggle = true
    var effectToggle = true
    var totalLengthOfAudio = ""
    var finalImage:UIImage!
    var shuffleState = false
    var repeatState = false
    var shuffleArray = [Int]()
    //
    var audioList:NSArray = []
    var songList:NSArray = []

    @IBOutlet weak var backgroundImageView: UIImageView!
//    @IBOutlet var songNo : UILabel!
    @IBOutlet var lineView : UIView!
    @IBOutlet weak var shadowImageView: UIImageView!
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet var songNameLabel : UILabel!
//    @IBOutlet var songNameLabelPlaceHolder : UILabel!
    @IBOutlet var progressTimerLabel : UILabel!
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    @IBOutlet var previousButton : UIButton!
    @IBOutlet var playButton : UIButton!
    @IBOutlet var nextButton : UIButton!
    @IBOutlet var listButton : UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    

    //MARK:- Lockscreen Media Control

    // This shows media info on lock screen - used currently and perform controls
    func showMediaInfo(){
        let artistName = AppUtils.sharedInstance.readArtistNameFromPlist(self.audioList,
                                                                         indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        //readArtistNameFromPlist(currentAudioIndex)
        let songName = self.songList[AppUtils.sharedInstance.currentSongIndex]
            //readSongNameFromPlist(currentAudioIndex)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : songName]
    }

    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEventType.remoteControl{
            switch event!.subtype{
            case UIEventSubtype.remoteControlPlay:
                play(self)
            case UIEventSubtype.remoteControlPause:
                play(self)
            case UIEventSubtype.remoteControlNextTrack:
                next(self)
            case UIEventSubtype.remoteControlPreviousTrack:
                previous(self)
            default:
                print("There is an issue with the control")
            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // run once
        audioList = AppUtils.sharedInstance.readFromPlist()
        // update song list
        songList = AppUtils.sharedInstance.readSongListFromPlist(audioList, indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        //assing background
        self.updateBackgroundImage()


        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ViewMgr.sharedInstance.currentVC = self
        // update song list
        songList = AppUtils.sharedInstance.readSongListFromPlist(audioList, indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        //this sets last listened trach number as current
        retrieveSavedTrackNumber()
        prepareAudio()
        updateLabels()
        assingSliderUI()
        setRepeatAndShuffle()
        //
        if (self.retrievePrevSongTitle() != AppUtils.sharedInstance.getCurrentSongName()) {
            print ("new song - start from beginning..")
            self.saveCurrentSongTitle()
        } else {
            print ("same song - continue")
            retrievePlayerProgressSliderValue()
        }
        playAudio()
        playButton.setImage(UIImage.init(named: "pause"), for:UIControlState.normal)
    }


    override func viewDidDisappear(_ animated: Bool) {
        stopAudiplayer()
    }


    func setRepeatAndShuffle(){
        shuffleState = UserDefaults.standard.bool(forKey: "shuffleState")
        repeatState = UserDefaults.standard.bool(forKey: "repeatState")
        if shuffleState == true {
            shuffleButton.isSelected = true
        } else {
            shuffleButton.isSelected = false
        }

        if repeatState == true {
            repeatButton.isSelected = true
        }else{
            repeatButton.isSelected = false
        }
    }






    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func updateBackgroundImage () {
        let bgImg = UIImage.init(named: AppUtils.sharedInstance.backgroundName)
        self.backgroundImageView.image = bgImg
    }

    // MARK:- AVAudioPlayer Delegate's Callback method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {

            if shuffleState == false && repeatState == false {
                // do nothing
                playButton.setImage( UIImage(named: "play"), for: UIControlState())
                return

            } else if shuffleState == false && repeatState == true {
            //repeat same song
                prepareAudio()
                playAudio()

            } else if shuffleState == true && repeatState == false {
            //shuffle songs but do not repeat at the end
            //Shuffle Logic : Create an array and put current song into the array then when next song come randomly choose song from available song and check against the array it is in the array try until you find one if the array and number of songs are same then stop playing as all songs are already played.
               shuffleArray.append(currentSongIndex)
                if shuffleArray.count >= audioList.count {
                playButton.setImage( UIImage(named: "play"), for: UIControlState())
                return

                }


                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentSongIndex = randomIndex
                prepareAudio()
                playAudio()

            } else if shuffleState == true && repeatState == true {
                //shuffle song endlessly
                shuffleArray.append(currentSongIndex)
                if shuffleArray.count >= audioList.count {
                    shuffleArray.removeAll()
                }


                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentSongIndex = randomIndex
                prepareAudio()
                playAudio()


            }

        }
    }


    //Sets audio file URL
    func setCurrentAudioPath(){

        currentAudio = self.songList[AppUtils.sharedInstance.currentSongIndex] as! String
            //readSongNameFromPlist(currentAudioIndex)
        currentAudioPath = URL(fileURLWithPath: Bundle.main.path(forResource: currentAudio, ofType: "mp3")!)
        print("\(currentAudioPath)")
    }

    func saveCurrentSongTitle() {
        UserDefaults.standard.set(currentAudio, forKey:"currentAudio")
        UserDefaults.standard.synchronize()
    }

    func retrievePrevSongTitle() -> String{
        if let prevSong = UserDefaults.standard.object(forKey: "currentAudio") as? String{
            return prevSong
        }
        return ""
    }


    func saveCurrentTrackNumber(){
        UserDefaults.standard.set(currentSongIndex, forKey:"currentSongIndex")
        UserDefaults.standard.synchronize()

    }

    func retrieveSavedTrackNumber(){
        if let currentAudioIndex_ = UserDefaults.standard.object(forKey: "currentSongIndex") as? Int{
            currentSongIndex = currentAudioIndex_
        }else{
            currentSongIndex = -1
        }
    }



    // Prepare audio for playing
    func prepareAudio(){
        setCurrentAudioPath()
        do {
            //keep alive audio at background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        audioPlayer = try? AVAudioPlayer(contentsOf: currentAudioPath)
        audioPlayer.delegate = self
        audioLength = audioPlayer.duration
        playerProgressSlider.maximumValue = CFloat(audioPlayer.duration)
        playerProgressSlider.minimumValue = 0.0
        playerProgressSlider.value = 0.0
        audioPlayer.prepareToPlay()
        showTotalSongLength()
        updateLabels()
        progressTimerLabel.text = "00:00"


    }

    //MARK:- Player Controls Methods
    func  playAudio(){
        audioPlayer.play()
        startTimer()
        updateLabels()
        saveCurrentTrackNumber()
        showMediaInfo()
    }

    func playNextAudio(){
        currentSongIndex += 1
        if currentSongIndex>audioList.count-1{
            currentSongIndex -= 1

            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }

    }


    func playPreviousAudio(){
        currentSongIndex -= 1
        if currentSongIndex<0{
            currentSongIndex += 1
            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }

    }


    func stopAudiplayer(){
        audioPlayer.stop();

    }

    func pauseAudioPlayer(){
        audioPlayer.pause()

    }


    //MARK:-

    func startTimer(){
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayerViewController.update(_:)), userInfo: nil,repeats: true)
            timer.fire()
        }
    }

    func stopTimer(){
        timer.invalidate()

    }


    func update(_ timer: Timer){
        if !audioPlayer.isPlaying{
            return
        }
        let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
        progressTimerLabel.text  = "\(time.minute):\(time.second)"
        playerProgressSlider.value = CFloat(audioPlayer.currentTime)
        UserDefaults.standard.set(playerProgressSlider.value , forKey: "playerProgressSliderValue")


    }

    func retrievePlayerProgressSliderValue(){
        let playerProgressSliderValue =  UserDefaults.standard.float(forKey: "playerProgressSliderValue")
        if playerProgressSliderValue != 0 {
            playerProgressSlider.value  = playerProgressSliderValue
            audioPlayer.currentTime = TimeInterval(playerProgressSliderValue)

            let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
            progressTimerLabel.text  = "\(time.minute):\(time.second)"
            playerProgressSlider.value = CFloat(audioPlayer.currentTime)

        }else{
            playerProgressSlider.value = 0.0
            audioPlayer.currentTime = 0.0
            progressTimerLabel.text = "00:00"
        }
    }



    //This returns song length
    func calculateTimeFromNSTimeInterval(_ duration:TimeInterval) ->(minute:String, second:String){
       // let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let second_ = abs(Int(duration.truncatingRemainder(dividingBy: 60)))

       // var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }



    func showTotalSongLength(){
        calculateSongLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }


    func calculateSongLength(){
        let time = calculateTimeFromNSTimeInterval(audioLength)
        totalLengthOfAudio = "\(time.minute):\(time.second)"
    }



    func updateLabels(){
        updateArtistNameLabel()
        updateAlbumNameLabel()
        updateSongNameLabel()
        updateAlbumArtwork()
    }


    func updateArtistNameLabel(){
        let artistName = AppUtils.sharedInstance.readArtistNameFromPlist(self.audioList,
                                                                         indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        //readArtistNameFromPlist()
        artistNameLabel.text = artistName
    }
    func updateAlbumNameLabel(){
        let albumName = AppUtils.sharedInstance.readAlbumNameFromPlist(self.audioList,
                                                                       indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        //readAlbumNameFromPlist(currentAudioIndex)
        albumNameLabel.text = albumName
    }

    func updateSongNameLabel(){
        let songName = self.songList[AppUtils.sharedInstance.currentSongIndex]
        //readSongNameFromPlist(currentAudioIndex)
        songNameLabel.text = songName as? String
    }

    func updateAlbumArtwork(){
        let artworkName = AppUtils.sharedInstance.readArtworkNameFromPlist(self.audioList,
                                                                           indexNumber: AppUtils.sharedInstance.currentArtistIndex)
        // reSize & rePosition
        let xpos = (kScreenWidth/2) - (kScalef/2)
        let ypos = (kScreenHeight/2) - (kScalef/2)
        self.albumArtworkImageView.frame = CGRect(x: xpos, y: ypos-50, width: kScalef, height: kScalef)
        self.shadowImageView.frame = CGRect(x: xpos, y: ypos-50, width: kScalef+20, height: kScalef+20)
        self.albumArtworkImageView.image = UIImage.init(named: artworkName)
        self.albumArtworkImageView.setRounded()
    }




    func assingSliderUI () {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "thumb")

        playerProgressSlider.setMinimumTrackImage(minImage, for: UIControlState())
        playerProgressSlider.setMaximumTrackImage(maxImage, for: UIControlState())
        playerProgressSlider.setThumbImage(thumb, for: UIControlState())
    }



    @IBAction func play(_ sender : AnyObject) {

        if shuffleState == true {
            shuffleArray.removeAll()
        }
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        if audioPlayer.isPlaying{
            pauseAudioPlayer()
            audioPlayer.isPlaying ? "\(playButton.setImage( pause, for: UIControlState()))" : "\(playButton.setImage(play , for: UIControlState()))"

        }else{
            playAudio()
            audioPlayer.isPlaying ? "\(playButton.setImage( pause, for: UIControlState()))" : "\(playButton.setImage(play , for: UIControlState()))"
        }
    }



    @IBAction func next(_ sender : AnyObject) {
        playNextAudio()
    }


    @IBAction func previous(_ sender : AnyObject) {
        playPreviousAudio()
    }




    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
        audioPlayer.currentTime = TimeInterval(sender.value)

    }


    @IBAction func userTapped(_ sender : UITapGestureRecognizer) {

        play(self)
    }

    @IBAction func userSwipeLeft(_ sender : UISwipeGestureRecognizer) {
        next(self)
    }

    @IBAction func userSwipeRight(_ sender : UISwipeGestureRecognizer) {
        previous(self)
    }

    @IBAction func userSwipeUp(_ sender : UISwipeGestureRecognizer) {
        // presentListTableView(self)
    }

    @IBAction func onPressListButton(_ sender: Any) {
        ViewMgr.sharedInstance.gotoPrev()
    }

    @IBAction func shuffleButtonTapped(_ sender: UIButton) {
        shuffleArray.removeAll()
        if sender.isSelected == true {
        sender.isSelected = false
        shuffleState = false
        UserDefaults.standard.set(false, forKey: "shuffleState")
        } else {
        sender.isSelected = true
        shuffleState = true
        UserDefaults.standard.set(true, forKey: "shuffleState")
        }



    }


    @IBAction func repeatButtonTapped(_ sender: UIButton) {
        if sender.isSelected == true {
            sender.isSelected = false
            repeatState = false
            UserDefaults.standard.set(false, forKey: "repeatState")
        } else {
            sender.isSelected = true
            repeatState = true
            UserDefaults.standard.set(true, forKey: "repeatState")
        }


    }







}
