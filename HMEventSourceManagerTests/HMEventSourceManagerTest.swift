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
import SwiftUtilitiesTests
import XCTest
@testable import HMEventSourceManager

public final class HMEventSourceManagerTest: XCTestCase {
    fileprivate var scheduler: TestScheduler!
    fileprivate var disposeBag: DisposeBag!
    fileprivate var sseManager: HMEventSourceManager!
    fileprivate var timeout: TimeInterval!
    
    override public func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        timeout = 20
        
        sseManager = HMEventSourceManager.builder()
            .with(networkChecker: Reachability())
            .with(userDefaults: UserDefaults.standard)
            .build()
    }
}

public extension HMEventSourceManagerTest {
    public func test_internetDisconnected_shouldTerminateConnection() {
        /// Setup
        let observer = scheduler.createObserver(Data.self)
        let expect = expectation(description: "Should have completed")
        let disposeBag = self.disposeBag!
        let sseManager = self.sseManager!
        let request = HMEventSourceManager.Request.builder().build()
        let terminateSbj = PublishSubject<Void>()
        
        let connectionObs = Observable<Data>.create({
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
            // When reachable is false, retry sequence is terminated.
            mainThread({sseManager.isReachable.value = false})
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertTrue(actualWait >= waitTime)
        XCTAssertTrue(actualWait < timeout)
    }
    
    public func test_internetReconnected_shouldRetryConnection() {
        /// Setup
        let observer = scheduler.createObserver(Data.self)
        let expect = expectation(description: "Should have completed")
        let disposeBag = self.disposeBag!
        let sseManager = self.sseManager!
        let request = HMEventSourceManager.Request.builder().build()
        let terminateSbj = PublishSubject<Void>()
        var currentIteration = 0
        
        let connectionObs = Observable<Data>.create({
            currentIteration += 1
            
            for _ in (0..<Int.max) {
                $0.onNext(Data())
            }
            
            return Disposables.create()
        })
        
        let waitTime: TimeInterval = 2
        let restartTimes = 10
        
        sseManager.rx.retryOnConnectivitySSE(request,
                                             connectionObs,
                                             terminateSbj)
            .observeOn(MainScheduler.instance)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// When
        let terminateTime = DispatchTime.now() + waitTime
        
        DispatchQueue.main.asyncAfter(deadline: terminateTime, execute: {
            mainThread({
                for _ in 0..<restartTimes {
                    // When reachable is false, old stream is terminated.
                    sseManager.isReachable.value = false
                    
                    // When reachable is true, a new stream is started.
                    sseManager.isReachable.value = true
                }
                
                // When this calls onNext, the stream will be terminated.
                terminateSbj.onNext(())
            })
        })
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertTrue(currentIteration > 0)
    }
}
