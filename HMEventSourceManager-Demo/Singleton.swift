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
    private static var instance: Singleton?
    
    public static var shared: Singleton {
        if let instance = instance {
            return instance
        } else {
            let instance = Singleton()
            self.instance = instance
            return instance
        }
    }
    
    public let sseManager: HMEventSourceManager
    
    init() {
        sseManager = HMEventSourceManager.builder()
            .with(networkChecker: Reachability())
            .with(userDefaults: UserDefaults.standard)
            .build()
    }
}
