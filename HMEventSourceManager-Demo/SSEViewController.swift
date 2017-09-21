//
//  SSEViewController.swift
//  HMEventSourceManager-Demo
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

public final class SSEViewController: UIViewController {
    fileprivate let disposeBag = DisposeBag()
    
    deinit {
        print("Deinit \(self)")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        let sseManager = Singleton.shared.sseManager
        
        sseManager.openSSEConnection()
            .logNext()
            .subscribe()
            .disposed(by: disposeBag)
    }
}
