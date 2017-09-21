//
//  SSEViewController.swift
//  HMEventSourceManager-Demo
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxDataSources
import RxSwift
import SwiftUtilities

public final class SSEViewController: UIViewController {
    @IBOutlet fileprivate weak var tableView1: UITableView!
    
    fileprivate let disposeBag: DisposeBag! = DisposeBag()
    fileprivate var sseManager: HMEventSourceManager!
    
    deinit {
        print("Deinit \(self)")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let username = "fe8b0af5-1b50-467d-ac0b-b29d2d30136b"
        let password = "ae10ff39ca41dgf0a8"
        let authString = "\(username):\(password)"
        let authData = authString.data(using: String.Encoding.utf8)
        let base64String = authData!.base64EncodedString(options: [])
        let authToken = "Basic \(base64String)"
        
        let request = HMEventSourceManager.Request.builder()
            .with(urlString: "http://127.0.0.1:8080/sse")
            .with(retryDelay: 3)
            .add(header: authToken, forKey: "Authorization")
            .build()
        
        let sseManager = Singleton().sseManager
        self.sseManager = sseManager
        
        sseManager.rx.retryOnConnectivitySSE(request)
            .logNext()
            .subscribe()
            .disposed(by: disposeBag)
    }
}

public final class SSECell: UITableViewCell {
    @IBOutlet fileprivate weak var label1: UILabel!
}
