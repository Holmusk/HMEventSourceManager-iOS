//
//  SaveLastEventIDTest.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 22/9/17.
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

public final class SaveLastEventIDTest: RootSSETest {
    public func test_saveLastEventIDOnEachBatch_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver([Event<Result>].self)
        let sseManager = self.newSSEManager()
        let times = 1000
        let dataSubject = PublishSubject<[Event<Result>]>()
        
        let request = HMSSEManager.Req.builder()
            .with(urlString: "https://holmusk.com")
            .with(headers: ["MockHeader" : "MockValue"])
            .build()
        
        var lastEventId: String?
        
        sseManager.triggerReachable().onNext(false)
        
        sseManager.openConnection(request, dataSubject)
            .observeOnMain()
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// When
        
        for index in 0..<times {
            let hasData = index == 0 ? true : Bool.random()
            var events: [Event<Result>] = []
            
            if hasData {
                let randomData = Result.randomData(10)
                lastEventId = randomData.last!.id!
                events = randomData.map(Event<Result>.dataReceived)
            } else {
                events = [Event<Result>.dummy]
            }
            
            sseManager.triggerReachable().onNext(true)
            dataSubject.onNext(events)
            
            /// Then
            XCTAssertEqual(sseManager.lastEventId(request), lastEventId)
            sseManager.triggerReachable().onNext(false)
        }
    }
}
