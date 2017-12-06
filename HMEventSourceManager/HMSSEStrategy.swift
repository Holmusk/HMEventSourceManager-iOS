//
//  HMSSEStrategy.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 6/12/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Represent a strategy to use with SSE stream when opening one.
///
/// - retryOnError: The stream simply retries whenever it encounters an error.
/// - retryOnConnectivity: The stream automatically terminates when there is
///                        no internet connection, and re-subscribes when
///                        connectivity is detected.
public enum HMSSEStrategy {
    case retryOnError
    case retryOnConnectivity
}
