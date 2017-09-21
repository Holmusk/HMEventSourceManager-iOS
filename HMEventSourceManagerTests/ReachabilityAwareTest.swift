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
        _ connectionTrigger: @escaping (AnyObserver<Bool>) -> Void,
        _ terminationTrigger: @escaping (AnyObserver<Void>) -> Void) {
        /// Setup
        let observer = scheduler.createObserver(Event<Result>.self)
        let expect = expectation(description: "Should have completed")
        let disposeBag = self.disposeBag!
        let sseManager = self.newSSEManager()
        let request = HMEventSourceManager.Request.builder().build()
        let terminateSbj = PublishSubject<Void>()
        
        let connectionObs = Observable<HMSSEvent<Data>>.create({
            $0.onError(Exception("Error!"))
            return Disposables.create()
        })
        
        let timeout = self.timeout!
        let waitTime: TimeInterval = 2
        let currentDate = Date()
        var actualWait: TimeInterval = 0
        
        sseManager.rx.reachabilityAwareSSE(request, connectionObs, terminateSbj)
            .observeOn(MainScheduler.instance)
            .doOnDispose({actualWait = Date().timeIntervalSince(currentDate)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// When
        let terminateTime = DispatchTime.now() + waitTime
        
        DispatchQueue.main.asyncAfter(deadline: terminateTime, execute: {
            
            // Trigger termination here.
            mainThread({
                connectionTrigger(sseManager.rx.triggerReachable)
                terminationTrigger(terminateSbj.asObserver())
            })
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertTrue(actualWait >= waitTime)
        XCTAssertTrue(actualWait < timeout)
    }
    
    public func test_terminateManually_shoudTerminateSSE() {
        test_terminateObsEmitsEvent_shoudTerminateSSE({_ in}, {$0.onNext(())})
    }
    
    public func test_internetDisconnected_shoudTerminateSSE() {
        test_terminateObsEmitsEvent_shoudTerminateSSE({$0.onNext(false)}, {_ in})
    }
}
