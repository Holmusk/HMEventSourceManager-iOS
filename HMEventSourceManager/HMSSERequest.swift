//
//  HMSSERequest.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// Req object for SSE manager.
public struct HMSSERequest {
    fileprivate var retryDelayIntv: TimeInterval
    fileprivate var urlStr: String?
    fileprivate var headers: [String : Any]
    fileprivate var sseStrategy: HMSSEStrategy
    
    fileprivate init() {
        retryDelayIntv = 0
        headers = [:]
        sseStrategy = .retryOnError
    }
}

extension HMSSERequest: HMSSERequestType {
    public func retryDelay() -> TimeInterval {
        return retryDelayIntv
    }
    
    public func urlString() throws -> String {
        if let urlString = self.urlStr {
            return urlString
        } else {
            throw Exception("URL String cannot be nil")
        }
    }
    
    public func additionalHeaders() -> [String : Any] {
        return headers
    }
    
    public func sseStreamStrategy() -> HMSSEStrategy {
        return sseStrategy
    }
}

extension HMSSERequest: BuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: Buildable
        
        fileprivate init() {
            request = Buildable()
        }
        
        /// Set the retry delay.
        ///
        /// - Parameter retryDelay: A TimeInterval value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(retryDelay: TimeInterval?) -> Self {
            if let retryDelay = retryDelay {
                request.retryDelayIntv = retryDelay
            }
            
            return self
        }
        
        /// Set the URL String value.
        ///
        /// - Parameter urlString: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlString: String?) -> Self {
            request.urlStr = urlString
            return self
        }
        
        /// Set the headers Dictionary.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(headers: [String : Any]?) -> Self {
            request.headers.removeAll()
            return add(headers: headers)
        }
        
        /// Add extra headers to this request.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(headers: [String : Any]?) -> Self {
            if let headers = headers {
                request.headers.updateValues(from: headers)
            }
            
            return self
        }
        
        /// Add a header to this request.
        ///
        /// - Parameters:
        ///   - header: A String value.
        ///   - key: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(header: String?, forKey key: String) -> Self {
            if let header = header {
                request.headers.updateValue(header, forKey: key)
            }
            
            return self
        }
        
        /// Set the SSE strategy.
        ///
        /// - Parameter sseStrategy: A HMSSEStrategy instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(sseStrategy: HMSSEStrategy) -> Self {
            request.sseStrategy = sseStrategy
            return self
        }
    }
}

extension HMSSERequest.Builder: BuilderType {
    public typealias Buildable = HMSSERequest
    
    @discardableResult
    public func with(buildable: HMSSERequest?) -> Self {
        if let buildable = buildable {
            return self
                .with(retryDelay: buildable.retryDelayIntv)
                .with(urlString: buildable.urlStr)
                .with(headers: buildable.headers)
                .with(sseStrategy: buildable.sseStrategy)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return request
    }
}

public extension HMSSERequest {
    public func url() throws -> URL {
        let urlString = try self.urlString()
        
        if let url = URL(string: urlString) {
            return url
        } else {
            throw Exception("URL cannot be constructed for \(urlString)")
        }
    }
}
