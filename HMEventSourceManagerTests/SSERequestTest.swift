//
//  SSERequestTest.swift
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

public final class SSERequestTest: RootSSETest {
    public func test_openConnection_shouldAddDefaultHeadersToRequest() {
        /// Setup
        let observer = scheduler.createObserver([Event<Result>].self)
        let sseManager = self.newSSEManager()
        let request = Request.builder().with(urlString: "MockURL").build()
        let dataSubject = BehaviorSubject<[Event<Result>]>(value: [])
        let cls = HMSSEManager.self
        var requestCreatedCount = 0
        
        let sseFn: (Request) -> Observable<[Event<Result>]> = {
            requestCreatedCount += 1
            let headers = $0.additionalHeaders() as! [String : String]
            XCTAssertEqual(headers[cls.acceptKey], cls.textEventStream)
            XCTAssertEqual(headers[cls.cacheControlKey], cls.noCache)
            return dataSubject
        }
        
        sseManager.rx.triggerReachable.onNext(false)
        
        sseManager.rx.openConnection(request, sseFn)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// When
        sseManager.rx.triggerReachable.onNext(true)
        
        /// Then
        XCTAssertEqual(requestCreatedCount, 1)
    }
}
