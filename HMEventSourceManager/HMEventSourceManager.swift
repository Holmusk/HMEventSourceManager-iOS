//
//  HMEventSourceManager.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 20/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMRequestFramework
import ReachabilitySwift
import RxReachability
import RxSwift
import SwiftUtilities

/// Use this class to handle SSE events.
public struct HMEventSourceManager {
    fileprivate let disposeBag: DisposeBag
    fileprivate var headers: [String : Any]
    fileprivate var nwChecker: Reachability?
    fileprivate var userDefs: UserDefaults?
    fileprivate var sseURL: URL?
    
    
    fileprivate init() {
        disposeBag = DisposeBag()
        headers = [:]
    }
    
    public func networkChecker() -> Reachability {
        if let nwChecker = self.nwChecker {
            return nwChecker
        } else {
            fatalError("Network checker cannot be nil")
        }
    }
    
    public func userDefaults() -> UserDefaults {
        if let userDefaults = self.userDefs {
            return userDefaults
        } else {
            fatalError("User defaults cannot be nil")
        }
    }
    
    public func targetURL() -> URL {
        if let url = self.sseURL {
            return url
        } else {
            fatalError("URL cannot be nil")
        }
    }
    
    public func additionalHeaders() -> [String : Any] {
        return headers
    }
    
    public func setupBindings() {}
}

extension HMEventSourceManager: BuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var manager: Buildable
        
        fileprivate init() {
            manager = Buildable()
        }
        
        /// Set the network checker instance.
        ///
        /// - Parameter networkChecker: A Reachability instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(networkChecker: Reachability?) -> Self {
            manager.nwChecker = networkChecker
            return self
        }

        /// Set the user defaults instance.
        ///
        /// - Parameter userDefaults: A UserDefaults instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(userDefaults: UserDefaults) -> Self {
            manager.userDefs = userDefaults
            return self
        }
        
        /// Set the url instance.
        ///
        /// - Parameter url: A URL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(url: URL?) -> Self {
            manager.sseURL = url
            return self
        }
        
        /// Set the url instance.
        ///
        /// - Parameter urlString: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlString: String?) -> Self {
            if let urlString = urlString {
                return self.with(url: URL(string: urlString))
            } else {
                return self
            }
        }
        
        /// Add headers to be used with the SSE URLSession.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(headers: [String : Any]?) -> Self {
            if let headers = headers {
                manager.headers.updateValues(from: headers)
            }
            
            return self
        }
        
        /// Add one header to the current headers.
        ///
        /// - Parameters:
        ///   - header: Any instance.
        ///   - key: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(header: Any?, forKey key: String) -> Self {
            if let header = header {
                manager.headers.updateValue(header, forKey: key)
            }
            
            return self
        }
        
        /// Set the headers to be added to the SSE URLSession.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(headers: [String : Any]?) -> Self {
            manager.headers.removeAll()
            return self.add(headers: headers)
        }
    }
}

extension HMEventSourceManager.Builder: BuilderType {
    public typealias Buildable = HMEventSourceManager
    
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(networkChecker: buildable.networkChecker())
                .with(userDefaults: buildable.userDefaults())
                .with(url: buildable.targetURL())
                .with(headers: buildable.additionalHeaders())
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return manager
    }
}
