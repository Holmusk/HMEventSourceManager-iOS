//
//  SSEViewController.swift
//  HMEventSourceManager-Demo
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxSwift
import SwiftUtilities
import SwiftUIUtilities

public final class SSEViewController: UIViewController {
    @IBOutlet fileprivate weak var tableView1: UITableView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var sseManager: HMSSEManager!
    fileprivate var dataSource: [HMSSEData] = []
    
    deinit {
        print("Deinit \(self)")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        guard let tableView = self.tableView1 else {
            return
        }
        
        tableView.registerNib(SSECell.self)
        tableView.estimatedRowHeight = 90
        tableView.delegate = self
        tableView.dataSource = self
        
        let username = "fe8b0af5-1b50-467d-ac0b-b29d2d30136b"
        let password = "ae10ff39ca41dgf0a8"
        let authString = "\(username):\(password)"
        let authData = authString.data(using: String.Encoding.utf8)
        let base64String = authData!.base64EncodedString(options: [])
        let authToken = "Basic \(base64String)"
        
        let request = HMSSEManager.Request.builder()
            .with(urlString: "http://127.0.0.1:8080/sse")
            .with(retryDelay: 3)
            .add(header: authToken, forKey: "Authorization")
            .build()
        
        let sseManager = Singleton().sseManager
        self.sseManager = sseManager
        
        sseManager.openConnection(request)
            .map(HMSSEvents.eventData)
            .throttle(1, scheduler: MainScheduler.instance)
            .observeOnMain()
            .doOnNext({[weak self] in self?.dataSource.append(contentsOf: $0)})
            .doOnNext({[weak tableView] _ in tableView?.reloadData()})
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension SSEViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.deque(SSECell.self, at: indexPath),
            let idLabel = cell.idLabel,
            let eventLabel = cell.eventLabel,
            let dataLabel = cell.dataLabel,
            let data = dataSource.element(at: indexPath.row)
        else {
            fatalError()
        }
        
        idLabel.text = data.id ?? "ID unavailable"
        eventLabel.text = data.event ?? "Event unavailable"
        dataLabel.text = data.data ?? "Data unavailable"
        return cell
    }
}

extension SSEViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

public final class SSECell: UITableViewCell {
    @IBOutlet fileprivate weak var idLabel: UILabel!
    @IBOutlet fileprivate weak var eventLabel: UILabel!
    @IBOutlet fileprivate weak var dataLabel: UILabel!
}
