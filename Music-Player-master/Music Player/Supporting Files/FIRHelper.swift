//
//  FIRHelper.swift
//  Music Player
//
//  Created by Arai on 7/8/18.
//  Copyright © 2018 Arai. All rights reserved.
//

import Foundation

import Firebase
import FirebaseStorage
import FirebaseInstanceID
import FirebaseMessaging
import FirebaseAnalytics


let kSTORAGE_BUCKET = "gs://" + readPLISTproperty(fileName: "GoogleService-Info", propertyName: "STORAGE_BUCKET")
let kAPI_KEY = "key=" + readPLISTproperty(fileName: "GoogleService-Info", propertyName: "SERVER_KEY")
let kPROJECT_ID = readPLISTproperty(fileName: "GoogleService-Info", propertyName: "PROJECT_ID")
var kSubscribeTopic = ""



func readPLISTproperty(fileName:String, propertyName:String) -> String  {
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    var plistData:[String:AnyObject] = [:]  //our data
    let plistPath:String? = Bundle.main.path(forResource: fileName, ofType: "plist")! //the path of the data
    let plistXML = FileManager.default.contents(atPath: plistPath!)! //the data in XML format
    do {
        //convert the data to a dictionary and handle errors.
        plistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                               options: .mutableContainersAndLeaves,
                                                               format: &format)as! [String:AnyObject]
        //assign the values in the dictionary to the properties
        return  plistData[propertyName] as! String
    }
    catch{ // error condition
        print("Error reading plist: \(error), format: \(format)")
        return "Error reading plist"
    }
}



func FIRAppConfig()
{
    // Configure Firebase
    // ------------------
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
}


protocol FIRHelperDelegate {
    func TokenRefreshed()
    func FIRLogUpdate (str:String)
}


class FIRHelper
{
    //properties
    static let sharedInstance = FIRHelper()
    private var dbRef: DatabaseReference?
    private var storageRef: StorageReference?
    private var uploadTask: StorageUploadTask?
    private var downloadTask: StorageDownloadTask?
    private var firHandle: UInt?
    private var firHandlePathRef: DatabaseReference?
    var delegate:FIRHelperDelegate?


    // if regisration is successful, this method will be use to inform Firebase about this new device.
    // With "FirebaseAppDelegateProxyEnabled": NO
    /*
     ======= IMPT ========
     Provide your APNs token and the token type in setAPNSToken:type:.
     Make sure that the value of type is correctly set:
     FIRInstanceIDAPNSTokenType.Sandbox -- for the sandbox environment, or
     FIRInstanceIDAPNSTokenType.Prod    -- for the production environment.

     If you don't set the correct type, messages are not delivered to your app.
     !!!!! When you exporting the APN certificate for PRODUCTION from your keychain to the .p12 file
     you have to select the actual certificate, not the private key.
     */
    func setAPNSToken (deviceToken: Data) {
        if kIsOnTestFlight {
            InstanceID.instanceID().setAPNSToken(deviceToken, type:InstanceIDAPNSTokenType.prod)
        } else {
            InstanceID.instanceID().setAPNSToken(deviceToken, type: InstanceIDAPNSTokenType.sandbox)
        }
    }

    // Firebase 4.0
    func setAPNSToken_OptV4 (deviceToken: Data)  {
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }

    func checkCurrentToken() -> String
    {
        if (InstanceID.instanceID().token() == nil) {
            print ("no token...wait..")
            self.createObserver()
            return "no token"

        } else {
            print ("checkCurrentToken() \(String(describing: InstanceID.instanceID().token()))")
            return InstanceID.instanceID().token()!
        }
    }

    // Firebase 4.0
    func checkCurrentToken_OptV4 () -> String
    {
        if (Messaging.messaging().fcmToken == nil) {
            print ("no token...wait..")
            self.createObserver()
            return "no token"

        } else {
            print ("checkCurrentToken() \(String(describing: Messaging.messaging().fcmToken))")
            return Messaging.messaging().fcmToken!
        }
    }

    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that should be done.
    func createObserver ()
    {
        print ("FIRHelper createObserver")
        self.delegate?.FIRLogUpdate (str: "FIrHelper createObserver...")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification(_:)),
                                               name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)
    }

    // Firebase 4.0
    func createObserver_OptV4 ()
    {
        print ("FIRHelper createObserver")
        self.delegate?.FIRLogUpdate (str: "FIrHelper createObserver...")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification_OptV4(_:)),
                                               name: NSNotification.Name.MessagingRegistrationTokenRefreshed,
                                               object: nil)
    }

    func removeObserver () {
        print ("FIRHelper.removeObserver....")
        self.delegate?.FIRLogUpdate(str: "FIRHelper removeObserver..")
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.InstanceIDTokenRefresh,
                                                  object: nil)
    }

    // Firebase 4.0
    func removeObserver_OptV4 () {
        print ("FIRHelper.removeObserver....")
        self.delegate?.FIRLogUpdate(str: "FIRHelper removeObserver..")
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.MessagingRegistrationTokenRefreshed,
                                                  object: nil)
    }


    //MARK: Refresh Token callback
    @objc func tokenRefreshNotification (_ notification: Notification)
    {
        print ("FIRToken was Refresh!!!!!!!!!!!!! \(String(describing: InstanceID.instanceID().token()))")
        self.delegate?.FIRLogUpdate(str: "FIRToken was refresh.....")

        if let refreshedToken = InstanceID.instanceID().token() {
            print("InstanceID token refreshed: \(refreshedToken)")
            self.delegate?.FIRLogUpdate(str: "with value-call delegate TokenRefreshed")
            //
            self.removeObserver()
            self.delegate?.TokenRefreshed()
        }
        // Connect to FCM since connection may have failed when attempted before having a token.
        self.connectToFcm()
    }


    @objc func tokenRefreshNotification_OptV4 (_ notification: Notification)
    {
        print ("FIRToken was Refresh!!!!!!!!!!!!! \(String(describing: Messaging.messaging().fcmToken))")
        self.delegate?.FIRLogUpdate(str: "FIRToken was refresh.....")

        if let refreshedToken = Messaging.messaging().fcmToken {
            print("InstanceID token refreshed: \(refreshedToken)")
            self.delegate?.FIRLogUpdate(str: "with value-call delegate TokenRefreshed")
            self.removeObserver_OptV4()
            self.delegate?.TokenRefreshed()
        }
        // Connect to FCM since connection may have failed when attempted before having a token.
        self.connectToFcm_OptV4()
    }


    private init ()
    {
        print ("FIRDatabase init");
        self.delegate?.FIRLogUpdate(str: "FIRDatebase init..")
        dbRef = Database.database().reference()
        storageRef = Storage.storage().reference(forURL: kSTORAGE_BUCKET)
    }


    // [START connect_to_fcm]

    func connectToFcm() {
        // Won't connect since there is no token
        guard InstanceID.instanceID().token() != nil else {
            return
        }
        //Disconnect previous FCM connection if it exists.
        Messaging.messaging().disconnect()
        Messaging.messaging().connect {
            (error) in
            if error != nil {
                print("Unable to connect with FCM. \(String(describing: error))")
                self.delegate?.FIRLogUpdate(str: "Unable to connectToFCM..")

            } else {
                print("Connected to FCM. \(String(describing: InstanceID.instanceID().token()))")
                self.delegate?.FIRLogUpdate(str: "Connected to FCM. \(String(describing: InstanceID.instanceID().token()))")
                if (!UserDefaultGetSubscription()) {
//                    self.subscribeToTopic()
                }
            }
        }
    }

    // Firebase 4.0
    func connectToFcm_OptV4 () {

        guard Messaging.messaging().fcmToken != nil else {
            return
        }
        // Disconnect previous FCM connection if it exists.
        Messaging.messaging().shouldEstablishDirectChannel = true

        if (Messaging.messaging().isDirectChannelEstablished) {
            print("Connected to FCM. \(String(describing: Messaging.messaging().fcmToken))")
            self.delegate?.FIRLogUpdate(str: "Connected to FCM. \(String(describing: Messaging.messaging().fcmToken))")
            if (!UserDefaultGetSubscription()) {
//                self.subscribeToTopic()
            }
        } else {
            print("Unable to connect with FCM)")
            self.delegate?.FIRLogUpdate(str: "Unable to connectToFCM..")
        }
    }
    // [END connect_to_fcm]


    func disconnectFCM () {
        Messaging.messaging().disconnect()
        print("Disconnected from FCM.")
        self.delegate?.FIRLogUpdate(str: "Disconnect from FCM.")
    }

    // Firebase 4.0
    func disconnectFCM_OptV4 () {
        Messaging.messaging().shouldEstablishDirectChannel = false
        print("Disconnected from FCM.")
        self.delegate?.FIRLogUpdate(str: "Disconnect from FCM.")
    }



    func checkFIRConnection (completion :@escaping (_ login:Bool) -> Void)
    {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously() { (user, error) in
                // ...
                if (error != nil) {
                    print ("login fail \(String(describing: error?.localizedDescription))")
                    completion (false)
                } else {
                    completion (true)
                    //  print ("return true")
                }
            }
        } else {
            completion (true)
        }
    }


    func uploadFileFromLocal (localurl:URL,
                              path:String,
                              typeOfContent:String,  // --- "audio/mpeg", "image/png"
        returnBlock: @escaping (_ success:Bool, _ url:String) -> Void)
    {
        guard let data = NSData.init(contentsOf: localurl) else {
            returnBlock (true, "")  // no image to upload
            return
        }

        let ref = storageRef!.child(path)

        // create file with metadata
        let metadata = StorageMetadata.init()
        metadata.contentType = typeOfContent

        uploadTask = ref.putData(data as Data, metadata: metadata, completion: {
            (mdata, error) in

            if (error != nil) {
                //print ("upload fail \(error?.localizedDescription)")
                returnBlock(false, (error!.localizedDescription))
            } else {
                let downloadurl = String(describing: mdata!.downloadURL()!)
                // print ("upload success \(downloadurl)")
                returnBlock(true, downloadurl)
            }

        })
    }


    func deleteFromStorageWithPath (path:String,
                                    returnBlock: @escaping (_ success:Bool) -> Void)
    {
        print (path)
        let ref = Storage.storage().reference(forURL: path)
        print (ref)
        ref.delete { (error) in
            if ((error) != nil) {
                print ((error?.localizedDescription)!)
                returnBlock (false)
            } else {
                returnBlock (true)
            }
        }
    }





    func registerUserToDbname (dbname: String,
                               withId: String,
                               dict: NSDictionary,
                               returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection() {
            (login:Bool) in
            if login {

                self.dbRef?.child(dbname).child(withId).setValue(dict, withCompletionBlock: {
                    (error, snaphot) in
                    print (snaphot)
                    if error != nil {
                        print ("registration fail \(String(describing: error?.localizedDescription))")
                        returnBlock(false)
                    } else {
                        returnBlock(true)
                    }
                })
            }
        }
    }

    func registerUserToDbname (dbname: String,
                               withId: String,
                               data: [String:Any],
                               returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection() {
            (login:Bool) in
            if login {

                self.dbRef?.child(dbname).child(withId).setValue(data, withCompletionBlock: {
                    (error, snaphot) in
                    print (snaphot)
                    if error != nil {
                        print ("registration fail \(String(describing: error?.localizedDescription))")
                        returnBlock(false)
                    } else {
                        returnBlock(true)
                    }
                })
            }
        }
    }



    func replaceDataToDbname (dbname: String,
                              withId: String,
                              data: [String:Any],
                              returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection()
            { (login:Bool) in

                if login {    // user is login

                    self.dbRef?.child(dbname).child(withId).setValue(data, withCompletionBlock:
                        { (error, snaphot) in

                            if error != nil {
                                print ("add fail \(String(describing: error?.localizedDescription))")
                                returnBlock(false)
                            } else {
                                returnBlock(true)
                            }
                    })
                }
        }
    }


    func replaceDataToDbname (dbname: String,
                              withId: String,
                              data: NSDictionary,
                              returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection()
            { (login:Bool) in

                if login {    // user is login

                    self.dbRef?.child(dbname).child(withId).setValue(data, withCompletionBlock:
                        { (error, snaphot) in
                            if error != nil {
                                print ("add fail \(String(describing: error?.localizedDescription))")
                                returnBlock(false)
                            } else {
                                returnBlock(true)
                            }
                    })
                }
        }
    }






    func queryUserDetailsfromDbname (dbname:String,
                                     query:String,
                                     returnBlock: @escaping (NSDictionary?) -> Void)
    {
        self.checkFIRConnection()
            { (login:Bool) in

                print ("checkFIRconnect \(login)")

                if login {

                    var ref = self.dbRef?.child(dbname)

                    if query != "" {
                        ref = ref?.child(query)
                    }
                    print (" query: \(String(describing: ref!))")

                    ref?.observeSingleEvent(of: .value, with:
                        { (snapshot) in
                            // Get user value
                            //print ("\(snapshot)")
                            if let dict = snapshot.value as? NSDictionary {
                                returnBlock (dict)
                            } else {
                                returnBlock (nil)
                            }

                    })
                    { (error) in
                        print ("error in connection: \(error.localizedDescription)")
                    }
                }
        }
    }

    func queryDatafromDbname (dbname:String,
                              query:String,
                              returnBlock: @escaping ([String:Any]?) -> Void)
    {
        self.checkFIRConnection() {
            (login:Bool) in

            if login {
                var ref = self.dbRef?.child(dbname)
                if query != "" {
                    ref = ref?.child(query)
                }
                //print (" query: \(String(describing: ref))")
                ref?.observeSingleEvent(of: .value, with:
                    { (snapshot) in
                        // Get user value
                        if let dict = snapshot.value as? [String:Any] {
                            returnBlock (dict)
                        } else {
                            returnBlock (nil)
                        }
                })
                { (error) in
                    print (error.localizedDescription)
                }
            }
        }
    }

    func queryStringfromPath (dbname: String, query:String,
                              returnBlock: @escaping (String) -> Void)
    {
        self.checkFIRConnection() {
            (login:Bool) in

            if login {
                var ref = self.dbRef?.child(dbname)
                if query != "" {
                    ref = ref?.child(query)
                }
                //print (" query: \(String(describing: ref))")
                ref?.observeSingleEvent(of: .value, with:{
                    (snapshot) in
                    // Get user value
                    if let value = snapshot.value as? String {
                        returnBlock (value)
                    } else {
                        returnBlock ("")
                    }
                })
                { (error) in
                    print (error.localizedDescription)
                }
            }
        }

    }


    func queryUserfromDbname (dbname:String,
                              query:String,
                              returnBlock: @escaping ([Any]?) -> Void)
    {
        self.checkFIRConnection() {
            (login:Bool) in

            if login {
                var ref = self.dbRef?.child(dbname)
                if query != "" {
                    ref = ref?.child(query)
                }
                ref?.observeSingleEvent(of: .value, with:
                    { (snapshot) in
                        //  print (snapshot.value as! NSDictionary)
                        // Get user value
                        if let dict = snapshot.value as? [Any] {
                            returnBlock (dict)
                        } else {
                            returnBlock (snapshot.children.allObjects)
                        }
                })
                { (error) in
                    print (error.localizedDescription)
                }
            }
        }
    }



    //    func downloadFileFromPath (path:String,
    //                               tolocalURL:URL,
    //                               returnBlock: @escaping (Bool) -> Void)
    //    {
    //        let ref = self.storageRef?.child(path)
    //        print (ref as Any)
    //        self.downloadTask = ref?.write(toFile: tolocalURL, completion: {
    //            (url, error) in
    //            print (url as Any)
    //            print (error?.localizedDescription as Any)
    //            if ((error) != nil)  {
    //                returnBlock (false)
    //            } else {
    //                returnBlock (true)
    //            }
    //        })
    //    }


    func addListenerToDbname (dbname:String,
                              toAcct:String,
                              fieldName:String,
                              returnArray: @escaping ([String:Any]?) -> Void)
    {
        self.checkFIRConnection(completion:
            { (login:Bool) in

                if login {

                    self.firHandlePathRef = self.dbRef?.child(dbname).child(toAcct)
                    if fieldName != "" {
                        self.firHandlePathRef = self.firHandlePathRef?.child(fieldName)
                    }

                    self.firHandlePathRef?.observe(DataEventType.value, with: {
                        (snapshot) in
                        // Get value of change
                        if let dict = snapshot.value as? [String:Any] {
                            returnArray (dict)
                        }
                    })
                }
        })
    }

    /* Method changed to use Delegate instead of async */
    func addListenerToDbname (dbname:String,
                              toAcct:String,
                              fieldName:String)
    {
        self.checkFIRConnection(completion:
            { (login:Bool) in

                if login {

                    self.firHandlePathRef = self.dbRef?.child(dbname).child(toAcct)
                    if fieldName != "" {
                        self.firHandlePathRef = self.firHandlePathRef?.child(fieldName)
                    }
                    print (self.firHandlePathRef!)

                    self.firHandlePathRef?.observe(DataEventType.value, with: {
                        (snapshot) in
                        // Get value of change
                        //                        print ("dfgdffhdh")
                        //                        if let dict = snapshot.value as? NSDictionary {
                        //returnDict (dict)
                        //                            print (dict)
                        self.delegate?.FIRLogUpdate(str:fieldName)
                        //                        }
                    })
                }
        })
    }




    func removeListener () {
        print ("FIR remove all listeners")
        self.firHandlePathRef?.removeAllObservers()
    }


    func updateValueInDbname (dbname: String,
                              value:Any,
                              returnBlock: @escaping (_ success:Bool) -> Void )
    {
        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                let ref = self.dbRef?.child(dbname)
                ref?.setValue(value, withCompletionBlock: {
                    (error, response) in

                    if error != nil {
                        print (error!.localizedDescription)
                        returnBlock(false)
                    } else {
                        returnBlock (true)
                    }
                })
            }
        })
    }


    func storeDatatoDbname (dbname:String,
                            toAcct:String,
                            fieldname:String,
                            nDict:[NSDictionary],
                            returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                var ref = self.dbRef?.child(dbname)

                if fieldname == "" {
                    ref = ref?.child(toAcct)
                } else {
                    ref = ref?.child(toAcct).child(fieldname)
                }

                ref?.setValue(nDict, withCompletionBlock: {
                    (error, response) in

                    if error != nil {
                        print (error!.localizedDescription)
                        returnBlock (false)
                    } else {
                        returnBlock (true)
                    }
                })

            }
        })
    }


    func storeMessagetoDbnameWithIdOption (dbname:String,
                                           toAcct:String,
                                           messageId:String,
                                           nDict:NSDictionary,
                                           returnBlock:@escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                var ref = self.dbRef?.child(dbname)

                if messageId == "" {
                    ref = ref?.child(toAcct)
                } else {
                    ref = ref?.child(toAcct).child(messageId)
                }

                ref?.setValue(nDict, withCompletionBlock: {
                    (error, response) in

                    if error != nil {
                        print (error!.localizedDescription)

                        returnBlock (false)
                    } else {
                        returnBlock (true)
                    }
                })

            }
        })
    }



    func deleteDatafromDbname (dbname: String,
                               toAcct:String,
                               id:String,
                               returnBlock: @escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                var deleteRef:DatabaseReference?
                let ref = self.dbRef?.child(dbname).child(toAcct)
                print ("...to delete \(id)")

                ref?.observeSingleEvent(of: .value, with:
                    { (snapshot) in
                        if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {

                            for i in 0..<snapshot.count {
                                let snap = snapshot[i]

                                if let remove = snap.childSnapshot(forPath: "keycontact_phone").value {
                                    let removeId = remove as! String
                                    if (removeId == id) {
                                        print ("found: \(snap.ref)")
                                        deleteRef = snap.ref
                                    }

                                }
                            }
                        }

                        if (deleteRef != nil) {
                            print ("remove........ !!")
                            deleteRef!.setValue(nil, withCompletionBlock:{
                                (error, response) in
                                if error != nil {
                                    print (error!.localizedDescription)
                                    returnBlock (false)
                                } else {
                                    print ("removed!! \(deleteRef!)")
                                    returnBlock (true)
                                }
                            })
                        } else {
                            returnBlock(false)
                        }

                }) // end oberveSingleEvent
            } // end login
        }) // end checkFIRConnection
    }


    func deleteMessagefromDbnameWithIdOption (dbname: String,
                                              toAcct:String,
                                              wMessageId:String,
                                              returnBlock: @escaping (_ success:Bool) -> Void)
    {
        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                var ref = self.dbRef?.child(dbname)

                if wMessageId == "" {
                    ref = ref?.child(toAcct).child("messages")
                } else if toAcct == "" {
                    ref = ref?.child(wMessageId)
                } else {
                    ref = ref?.child(toAcct).child("messages").child(wMessageId)
                }

                ref?.setValue(nil, withCompletionBlock: {
                    (error, response) in
                    if error != nil {
                        print (error!.localizedDescription)
                        returnBlock (false)
                    } else {
                        returnBlock (true)
                    }
                })
            }
        })
    }






    func deleteUserfromDbname (dbname:String,
                               wAcct:String,
                               returnBlock:@escaping (_ success:Bool) -> Void)
    {

        self.checkFIRConnection(completion: {
            (login:Bool) in

            if login {

                guard let ref = self.dbRef?.child(dbname).child(wAcct) else {
                    print ("invalid path")
                    return
                }

                ref.setValue(nil, withCompletionBlock: {
                    (error, response) in

                    if error != nil {
                        print (error!.localizedDescription)
                        returnBlock (false)
                    } else {
                        returnBlock (true)
                    }

                })
            }
        })
}
}
