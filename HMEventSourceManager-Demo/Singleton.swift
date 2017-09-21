//
//  Singleton.swift
//  HMEventSourceManager-Demo
//
//  Created by Hai Pham on 20/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Foundation
import HMEventSourceManager
import HMRequestFramework
import ReachabilitySwift
import RxSwift

public struct Singleton {
    private static let instance = Singleton()
    
    public static var shared: Singleton {
        return instance
    }
    
    public let sseManager: HMEventSourceManager
    
    private init() {
        let username = "fe8b0af5-1b50-467d-ac0b-b29d2d30136b"
        let password = "ae10ff39ca41dgf0a8"
        let authString = "\(username):\(password)"
        let authData = authString.data(using: String.Encoding.utf8)
        let base64String = authData!.base64EncodedString(options: [])
        let authToken = "Basic \(base64String)"
        
        sseManager = HMEventSourceManager.builder()
            .with(urlString: "http://127.0.0.1:8080/sse")
            .with(networkChecker: Reachability())
            .with(userDefaults: UserDefaults.standard)
            .add(header: authToken, forKey: "Authorization")
            .build()
    }
}
