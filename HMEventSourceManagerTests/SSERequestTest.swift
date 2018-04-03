//
//  SSERequestTest.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Reachability
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
        let sseManager = self.newSSEManager()
        
        let request = Req.builder()
            .with(urlString: "MockURL")
            .with(retryDelay: 1000)
            .build()
        
        let cls = HMSSEManager.self
        var requestCreatedCount = 0
        
        sseManager.addDefaultParamsInterceptor = {
            requestCreatedCount += 1
            let headers = $0.additionalHeaders() as! [String : String]
            XCTAssertEqual(headers[cls.acceptKey], cls.textEventStream)
            XCTAssertEqual(headers[cls.cacheControlKey], cls.noCache)
        }
        
        sseManager.openConnection(request, .background)
            .subscribeOnConcurrent(qos: .background)
            .observeOnMain()
            .subscribe()
            .disposed(by: disposeBag)
        
        waitOnMainThread(waitDuration!)
        
        /// Then
        XCTAssertEqual(requestCreatedCount, 1)
    }
}
