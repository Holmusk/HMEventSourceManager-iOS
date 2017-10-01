//
//  HMSSEManager.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 20/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import ReachabilitySwift
import RxReachability
import RxSwift
import SwiftUtilities

/// Use this class to handle SSE events.
public struct HMSSEManager {
    fileprivate let disposeBag: DisposeBag
    fileprivate var nwChecker: Reachability?
    fileprivate var userDefs: UserDefaults?
    
    // Since reachability.rx does not relay that last event, we need to store
    // it somewhere for easy access when opening a new SSE connection.
    let isReachable: BehaviorSubject<Bool>
    
    public let newlineCharacters: [String]
    
    fileprivate init() {
        disposeBag = DisposeBag()
        isReachable = BehaviorSubject<Bool>(value: true)
        newlineCharacters = ["\r\n", "\n", "\r"]
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
    
    fileprivate func setupBindings() {
        let disposeBag = self.disposeBag
        let networkChecker = self.networkChecker()
        let isReachable = self.isReachable
        
        // Get the current reachability status, then subscribe to notifications
        // later.
        isReachable.onNext(networkChecker.isReachable)
        
        try? networkChecker.startNotifier()
        
        networkChecker.rx.isReachable
            .distinctUntilChanged()
            .observeOnMain()
            .bind(to: isReachable)
            .disposed(by: disposeBag)
    }
    
    fileprivate func onInstanceBuilt() {
        setupBindings()
    }
}

extension HMSSEManager: BuildableType {
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
    }
}

extension HMSSEManager.Builder: BuilderType {
    public typealias Buildable = HMSSEManager
    
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(networkChecker: buildable.networkChecker())
                .with(userDefaults: buildable.userDefaults())
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        manager.onInstanceBuilt()
        return manager
    }
}
