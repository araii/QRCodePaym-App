//
//  AppUtils.swift
//  PRESmvp
//
//  Created by Arai on 28/12/16.
//  Copyright © 2016 tribalddb. All rights reserved.
//


import Foundation
import UIKit
import UserNotifications


// MARK: Extensions...
extension UIImageView {

    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

extension String {
    var stringByRemovingPrefixSymbols : [String] {
        return components(separatedBy: ":")
    }
}




// MARK: Edit for FIRHelper..
let kIsOnTestFlight = false
let kForceAccess = false
func UserDefaultGetSubscription () -> Bool {
    return true
}
func UserDefaultSetSubscription (done:Bool) {
}
func UserDefaultGetUUID () -> String {
    let deviceUUID: String = (UIDevice.current.identifierForVendor?.uuidString)!
    print ("UserDefaultGetUUID set: \(deviceUUID)")
    return deviceUUID
}

let kScreenHeight = Double(UIScreen.main.bounds.size.height)
let kScreenWidth = Double(UIScreen.main.bounds.size.width)






class AppUtils: NSObject  {


    // p-singleton~~
    static let sharedInstance = AppUtils()
    //
    var timer:Timer?
    var presetDateFormat:DateFormatter = DateFormatter.init()
    var isBackgroundMode = false

    
    func getVC (vcName:String, storyboardName:String) -> UIViewController
    {
        let storyboard = UIStoryboard.init(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: vcName)
    }
    
    
    func returnDoubleDigits (int: Int) -> String
    {
        if (int < 10) {
            let str = "0" + String(int)
            return str
        } else {
            return String(int)
        }
    }
    
    
    func stringToInt (inputString: String) -> Int {
        guard let int = Int(inputString) else {
            print ("stringToInt: Cannot convert to int")
            return -1
        }
        return int
    }

    
    
    func moveView (view:UIView, direction:String)
    {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        var rect = view.frame
        
        if (direction == "up") {
            rect.origin.y -= 80
            rect.size.height += 80
        } else if (direction == "down") {
            rect.origin.y += 80
            rect.size.height -= 80
        }
        
        view.frame = rect
        UIView.commitAnimations()
    }
    

    //    func getAbbrFromStrings (str:String, str2:String) -> String
    //    {
    //        var a = ""
    //        var b = ""
    //
    //        if (str.characters.first != nil) {
    //            a = String(str.characters.first!)
    //        }
    //
    //        if (str2.characters.first != nil) {
    //            b = String(str2.characters.first!)
    //        }
    //        return ("\(a) \(b)")
    //    }

    
    //    func displayDifferentFonts (boldColor:UIColor, boldText:String, normalText:String) -> NSMutableAttributedString
    //    {
    //        let highLightTxt = boldText
    //        let fullmessage = boldText + " " + normalText
    //        var myMutableString:NSMutableAttributedString? = nil
    //
    //        guard let bodyFont = UIFont(name:"AvenirNext-Regular", size: 17.0) else {
    //            print ("bodyFont not found")
    //            return myMutableString!
    //        }
    //
    //        guard let titleFont = UIFont(name: "AvenirNextCondensed-Bold", size: 17.0) else {
    //            print ("titleFont not found")
    //            return myMutableString!
    //        }
    //
    //        myMutableString = NSMutableAttributedString(string: fullmessage,
    //                                                    attributes: [NSFontAttributeName:bodyFont])
    //        myMutableString?.addAttribute( NSFontAttributeName,
    //                                      value: titleFont,
    //                                      range: NSRange( location:0, length:highLightTxt.characters.count))
    //        myMutableString?.addAttribute( NSForegroundColorAttributeName,
    //                                      value: boldColor,
    //                                      range: NSRange( location:0, length:highLightTxt.characters.count))
    //        return myMutableString!
    //    }

    
    func stringToDouble (inputString: String) -> Double {
        let dV = Double (inputString)
        guard dV != nil else {
            print ("ErrorMessage.kBadString")
            return 0.0
        }
        return dV!
    }

    
    // MARK: Date Methods
    func getDateTime (timeStamp:Date) -> String {
        self.presetDateFormat.dateFormat = "dd-MM-yyyy 'at' HH:mm"
        return self.presetDateFormat.string(from: timeStamp)
    }
    
    func getStringFromDateTime (timeStamp:Date) -> String
    {
        self.presetDateFormat.dateFormat = "dd/MM/yyyy"
        return self.presetDateFormat.string(from: timeStamp)
    }
    
    func getMonthFromDateTime (timeStamp:Date) -> Int
    {
        self.presetDateFormat.dateFormat = "MM"
        let str = self.presetDateFormat.string(from: timeStamp)
        return self.stringToInt(inputString: str)
    }
    
    func getDayFromDateTime (timeStamp:Date) -> Int
    {
        self.presetDateFormat.dateFormat = "dd"
        let str = self.presetDateFormat.string(from: timeStamp)
        return self.stringToInt(inputString: str)

    }
    
    func getYearFromDateTime (timeStamp:Date) -> Int
    {
        self.presetDateFormat.dateFormat = "yyyy"
        let str = self.presetDateFormat.string(from: timeStamp)
        return self.stringToInt(inputString: str)
    }
    
    
    // MARK: Documents Directory
    func getDocumentsDirectory() -> NSString
    {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    }
    
    
    func createFileInLocal (image:UIImage, filename:String) -> String
    {
        let path = getDocumentsDirectory().appendingPathComponent(filename)
        let imageData = UIImagePNGRepresentation (image)
        let success = FileManager.default.createFile(atPath: path as String, contents: imageData, attributes: nil)
        if success {
            do {
                try imageData?.write(to: URL.init(fileURLWithPath: path))
                return path
                
            } catch {
                return "null"
            }
            
        } else {
            return "null"
        }
        
    }
    
    
    // NOTE: All images will be saved according to #phonenumber OR #message_id OR profile.png
    func loadPhotoToLocalCache (loadPath:String, saveFile:String,
                                _ complete: @escaping (_ success:Bool, _ returnPath:String ) -> Void)
    {
        let url = URL(string: loadPath)
        URLSession.shared.dataTask(with: url!, completionHandler: {
            
            (imgdata, response, error) in
            if (error != nil) {
                print (error?.localizedDescription as Any)
            } else {
                
                guard let img = UIImage.init(data: imgdata!) else {
                    print ("invalid image for \(loadPath)")
                    complete (false, "")
                    return
                }
                // save the image..
                let urlstring = self.createFileInLocal (image: img,
                                                        filename: saveFile)
                if (urlstring != "null") {
                    complete (true, saveFile)
                    // print ("image saved \(loadPath) \(urlstring)")
                } else {
                    complete (false, saveFile)
                    //  print ("image not save \(loadPath)")
                }
            }
        }).resume()
    }
    
    
    func loadPhotoToLocalCache (loadPath:String,
                                _ complete: @escaping (_ success:Bool, _ loadedImage: UIImage?) -> Void)
    {
        let url = URL (string: loadPath)
        URLSession.shared.dataTask(with: url!, completionHandler: {
            
            (imgdata, response, error) in
            if (error != nil) {
                print (error?.localizedDescription as Any)
                
            } else {
                
                guard let img = UIImage.init(data:imgdata!) else {
                    print ("invalid image for \(loadPath)")
                    complete (false, nil)
                    return
                }
                // return image
                complete (true, img)
            }
        }).resume()
    }



    var currentArtistIndex:Int = -1
    var currentSongIndex:Int = -1
    var backgroundName = "background7.png"
    var loadedPaidSongs = [""]


    //Read plist file and creates an array of dictionary
    func readFromPlist() -> NSArray {
        let path = Bundle.main.path(forResource: "list", ofType: "plist")
        return NSArray(contentsOfFile:path!)!
    }

    func readArtistNameFromPlist(_ audioList:NSArray, indexNumber: Int) -> String {
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artistName = infoDict.value(forKey: "artistName") as! String
        return artistName
    }

    func readAlbumNameFromPlist(_ audioList:NSArray, indexNumber: Int) -> String {
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let albumName = infoDict.value(forKey: "albumName") as! String
        return albumName
    }

    func readSongListFromPlist (_ audioList:NSArray, indexNumber: Int) -> NSArray {
        var infoDict = NSDictionary()
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let songList = infoDict.value(forKey: "songList") as! NSArray
        return songList
    }

    func readArtworkNameFromPlist(_ audioList:NSArray, indexNumber: Int) -> String {
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artworkName = infoDict.value(forKey: "albumArtwork") as! String
        return artworkName
    }

    func getCurrentSongName () -> String {
        let audioList = self.readFromPlist()
        let songlist = self.readSongListFromPlist(audioList, indexNumber: self.currentArtistIndex)
        return songlist[self.currentSongIndex] as! String
    }

    func checkCurrentSongPayment () -> Bool {
        let song = self.getCurrentSongName()
        if (self.loadedPaidSongs.contains(song)) {
            return true
        }
        return false
    }


    // MARK: FireBase Methods
    func checkUserFirebase (_ complete: @escaping (_ success:Bool) -> Void) {
        let queryUrl = UserDefaultGetUUID()
        FIRHelper.sharedInstance.queryUserDetailsfromDbname(dbname: "QRCodePaym",
                                                            query: queryUrl, returnBlock:
            { (dict) in
                if (dict != nil) {
                    guard let paidSongs =  dict?["PaidSongs"] as? [String] else {
                        print ("error: can't parse data")
                        complete(true)
                        return
                    }
                    self.loadedPaidSongs = paidSongs as [String]
                    print (self.loadedPaidSongs)
                    complete (true)

                } else {
                    print ("user not found")
                    let postDict = ["PaidSongs": ["nil"]]
                    FIRHelper.sharedInstance.registerUserToDbname(dbname: "QRCodePaym",
                                                                  withId: queryUrl,
                                                                  dict: postDict as NSDictionary,
                                                                  returnBlock:
                        {(success) in
                            print ("added \(success)")
                            complete (true)
                    })
                }
        })
    }



    func addListenerToFirebase () {
        let queryUrl = UserDefaultGetUUID()
        FIRHelper.sharedInstance.addListenerToDbname(dbname: "QRCodePaym",
                                                     toAcct: queryUrl,
                                                     fieldName: "PaidSongs")
    }


    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.applying(transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }




}

