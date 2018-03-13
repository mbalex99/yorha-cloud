//
//  PostThoughtViewController.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/13/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit
import Cartography
import RealmSwift

class PostThoughtViewController: UIViewController {
    
    let realm = Realm.main
    
    lazy var textView: UITextView = {
        let t = UITextView()
        t.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        t.font = UIFont.systemFont(ofSize: 16)
        t.keyboardDismissMode = .interactive
        return t
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Thought"
        
        view.addSubview(textView)
        
        constrain(textView) { (textView) in
            textView.left == textView.superview!.left
            textView.right == textView.superview!.right
            textView.top == textView.superview!.top
            textView.bottom == textView.superview!.bottom
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonDidClick))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(postButtonDidClick))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    @objc func cancelButtonDidClick() {
        dismiss(animated: true, completion: nil)
    }

    @objc func postButtonDidClick() {
        guard let me = realm.object(ofType: User.self, forPrimaryKey: SyncUser.current!.identity!) else { return }
        let newThought = Thought()
        newThought.body = textView.text
        try! realm.write {
            me.thoughts.append(newThought)
        }
        dismiss(animated: true, completion: nil)
    }
}
