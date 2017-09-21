//
//  HMEventSourceManagerTest.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 20/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import ReachabilitySwift
import RxReachability
import RxSwift
import RxTest
import SwiftUtilities
import XCTest
@testable import HMEventSourceManager

public final class HMEventSourceManagerTest: XCTestCase {
    fileprivate var disposeBag: DisposeBag!
    fileprivate var reachability: Reachability!
    
    override public func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        reachability = Reachability()!
        try! reachability.startNotifier()
    }
    
    override public func tearDown() {
        super.tearDown()
        reachability.stopNotifier()
    }
}
