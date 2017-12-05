//
//  ReachabilityAwareTest.swift
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
import SwiftUtilitiesTests
import XCTest
@testable import HMEventSourceManager

public final class ReachabilityAwareTest: RootSSETest {
    public func test_terminateObsEmitsEvent_shoudTerminateSSE(
        _ connectionTrigger: @escaping (AnyObserver<Bool>) -> Void) {
        /// Setup
        let observer = scheduler.createObserver([Event<Result>].self)
        let expect = expectation(description: "Should have completed")
        let disposeBag = self.disposeBag!
        let sseManager = self.newSSEManager()
        
        let request = HMSSEManager.Request.builder()
            .with(urlString: "MockUrl")
            .build()
        
        let connectionObs = Observable<HMSSEvent<Data>>.create({
            $0.onError(Exception("Error!"))
            return Disposables.create()
        })
        
        let timeout = self.timeout!
        let waitTime: TimeInterval = 2
        let currentDate = Date()
        var actualWait: TimeInterval = 0
        
        sseManager.reachabilityAwareSSE(request, connectionObs)
            .subscribeOnConcurrent(qos: .background)
            .observeOnConcurrent(qos: .background)
            .doOnDispose({actualWait = Date().timeIntervalSince(currentDate)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// When
        let terminateTime = DispatchTime.now() + waitTime
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: terminateTime, execute: {
            
            // Trigger termination here.
            connectionTrigger(sseManager.triggerReachable())
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertTrue(actualWait >= waitTime)
        XCTAssertTrue(actualWait < timeout)
    }
    
    public func test_internetDisconnected_shoudTerminateSSE() {
        test_terminateObsEmitsEvent_shoudTerminateSSE({$0.onNext(false)})
    }
}
