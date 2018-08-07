//
//  Constants.swift
//  NavigationBasic
//
//  Created by Arai on 25/5/18.
//  Copyright © 2018 Arai. All rights reserved.
//

import Foundation

// MARK: Constants
//let kBuildV = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
//let kBundleV = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
//let kVersionCurrent = "\(kBundleV).\(kBuildV)"
let kPaymentURL = readPLISTproperty(fileName: "GoogleService-Info", propertyName: "FUNCTION_URL")



enum UserDataKeywords:String {
    case kLaunched = "launched"
    case kFirstTimeView = "firstTimeView"
    case kFirToken = "firToken"
    case kViewMessageId = "view_message_id"
    case kViewStatus = "view_status"
    case kUserDetail = "userDetails"
    case kLastName = "lastName"
    case kFirstName = "firstName"
    case kNric = "nric"
    case kImagePath = "imagePath"
    case kPhone = "phone"
    case kBirthday = "dob"
    case kBloodType = "bloodType"
    case kAddress = "address"
    case kGender = "gender"
    case kUserUUID = "userUUID"
    case kKeyContacts = "keycontacts"
    case kLocLat = "lat"
    case kLocLng = "lng"
    case kDisaster = "disaster"
    case kSOS = "sos_status" // < this will be just a time string
}
