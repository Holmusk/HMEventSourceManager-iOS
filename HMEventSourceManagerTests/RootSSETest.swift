//
//  RootSSETest.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMRequestFramework
import ReachabilitySwift
import RxSwift
import RxTest
import SwiftUtilities
import XCTest
@testable import HMEventSourceManager

public class RootSSETest: XCTestCase {
    public typealias Event = HMSSEvent
    public typealias Result = HMEventSourceManagerType.Result
    public var scheduler: TestScheduler!
    public var disposeBag: DisposeBag!
    public var timeout: TimeInterval!
    
    override public func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        timeout = 10
    }
    
    public func newSSEManager() -> HMMockEventSourceManager {
        let sseManager = HMEventSourceManager.builder()
            .with(networkChecker: Reachability())
            .with(userDefaults: UserDefaults.standard)
            .build()
        
        return HMMockEventSourceManager(sseManager)
    }
}
