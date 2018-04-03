//
//  HMSSEDelegate.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftFP
import SwiftUtilities

public final class HMSSEDelegate: NSObject {
  public typealias ResponseDisposition = URLSession.ResponseDisposition
  fileprivate let observer: AnyObserver<Try<HMSSEvent<Data>>>

  deinit {
    debugPrint("Deinit \(self)")
  }

  public func removeCallbacks() {}

  public init<O>(_ observer: O) where O: ObserverType, O.E == Try<HMSSEvent<Data>> {
    self.observer = observer.asObserver()
  }
}

extension HMSSEDelegate: URLSessionDataDelegate {
  public func urlSession(_ session: URLSession,
                         dataTask: URLSessionDataTask,
                         didReceive data: Data) {
    Preconditions.checkNotRunningOnMainThread(nil)

    // When the connection is first opened, there might be a dummy event
    // with 1 byte that we can ignore so as not to push two concurrent
    // events onto the observer.
    if data.count > 1 {
      observer.onNext(Try.success(HMSSEvent.dataReceived(data)))
    }
  }

  public func urlSession(_ session: URLSession,
                         dataTask: URLSessionDataTask,
                         didReceive response: URLResponse,
                         completionHandler: @escaping (ResponseDisposition) -> Void) {
    Preconditions.checkNotRunningOnMainThread(nil)
    completionHandler(.allow)
    observer.onNext(Try.success(HMSSEvent.connectionOpened))
  }

  public func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {
    Preconditions.checkNotRunningOnMainThread(nil)

    if let error = error as NSError?, error.code != 999 {
      observer.onNext(Try.failure(error))
    } else if error == nil {
      let error = Exception("Data transfer completed - resubscribing.")

      // We throw error here as well to access retryWhen.
      observer.onNext(Try.failure(error))
    } else {
      observer.onCompleted()
    }
  }
}
