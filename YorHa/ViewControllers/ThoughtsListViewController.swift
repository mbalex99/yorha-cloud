//
//  ThoughstListViewController.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/13/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit
import Cartography
import RealmSwift

class ThoughtsListHeaderView: UIView {
    
    let spriteImageView = SpriteImageView()
    let detailLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        addSubview(spriteImageView)
        
        constrain(spriteImageView) { (spriteImageView) in
            spriteImageView.height == 68
            spriteImageView.width == 68
            spriteImageView.centerX == spriteImageView.superview!.centerX
            spriteImageView.centerY == spriteImageView.superview!.centerY
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ThoughtsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    lazy var tableView: UITableView = {
        let t = UITableView()
        return t
    }()
    
    var thoughts: Results<Thought> {
        return user.thoughts.sorted(byKeyPath: "timestamp", ascending: false)
    }
    
    var notificationToken: NotificationToken?
    
    let user: User
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        constrain(tableView) { (tableView) in
            tableView.left == tableView.superview!.left
            tableView.bottom == tableView.superview!.bottom
            tableView.top == tableView.superview!.top
            tableView.right == tableView.superview!.right
        }
        
        title = user.nickname
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.dataSource = self
        tableView.delegate = self
        
        notificationToken = thoughts.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonDidClick))
    }
    
    @objc func cancelButtonDidClick() {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ThoughtsListHeaderView()
        header.spriteImageView.sd_setImage(with: URL(string: user.spriteUrl)!, completed: nil)
        return header
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thoughts.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell()
        let thought = self.thoughts[indexPath.row]
        cell.textLabel?.text = thought.body
        return cell
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}
