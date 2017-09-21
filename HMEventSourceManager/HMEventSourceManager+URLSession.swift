//
//  HMEventSourceManager+URLSession.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxSwift
import SwiftUtilities

public extension HMEventSourceManager {
    public typealias Request = HMNetworkRequest
    
    /// Get a cloned request with some default parameters.
    ///
    /// - Parameter request: A Request instance.
    /// - Returns: A Request instance.
    func requestWithDefaultParams(_ request: Request) -> Request {
        return request.cloneBuilder()
            .with(operation: .get)
            .with(retries: Int.max)
            .add(header: "text/event-stream", forKey: "Accept")
            .add(header: "no-cache", forKey: "Cache-Control")
            .build()
    }
    
    /// Get a URLSessionConfiguration to use with SSE URLSession.
    ///
    /// - Parameter request: A Request instance.
    /// - Returns: A URLSessionConfiguration instance.
    func urlSessionConfig(_ request: Request) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(Int.max)
        config.timeoutIntervalForResource = TimeInterval(Int.max)
        config.httpAdditionalHeaders = request.headers()
        return config
    }
}
