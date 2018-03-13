//
//  ViewController.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift

class WelcomeViewController: FormViewController {
    
    static let TEXT_ROW = "TEXT_ROW"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
        self.navigationItem.largeTitleDisplayMode = .always
        
        form +++ Section()
            <<< TextRow(WelcomeViewController.TEXT_ROW) { row in
                row.title = "Nickname: "
                row.cell.textField.autocorrectionType = .no
                row.cell.textField.autocapitalizationType = .none
            }
            +++ Section()
            <<< ButtonRow() { row in
                row.title = "Login"
            }.onCellSelection({ [weak self] (_, _) in
                self?.attemptLogin()
            })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove self from navigation hierarchy
        guard let viewControllers = navigationController?.viewControllers,
            let index = viewControllers.index(of: self) else { return }
        navigationController?.viewControllers.remove(at: index)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let cell = self.form.rowBy(tag: WelcomeViewController.TEXT_ROW)?.baseCell as! TextCell
        cell.textField.becomeFirstResponder()
    }

    func attemptLogin() {
        var nickname = form.values()[WelcomeViewController.TEXT_ROW] as? String ?? ""
        nickname = nickname.lowercased()
        if !nickname.matches("^[a-z0-9_-]{3,30}$") {
            let alert = UIAlertController(title: "Uh Oh", message: "We only support characters a-z, 0-9, _, - and only between 3 and 30 characters", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
        let creds = SyncCredentials.nickname(nickname, isAdmin: true)
        SyncUser.logIn(with: creds, server: URL(string: Constants.AUTH_URL)!) { [weak self] (user, error) in
            if let error = error {
                let alert = UIAlertController(title: "Uh Oh", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                    
                }))
                self?.present(alert, animated: true, completion: nil)
            } else {
               self?.setupAndEnter(nickname: nickname)
            }
        }
    }

    
    func setupAndEnter(nickname: String) {
        Realm.mainAsync(callback: { [weak self] (realm, error) in
            if let error = error {
                let alert = UIAlertController(title: "Uh Oh", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                    
                }))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            if let realm = realm {
                if realm.object(ofType: User.self, forPrimaryKey: SyncUser.current!.identity) == nil {
                    SpriteService().getRandomSprite(callback: { (sprite, err) in
                        try! realm.write {
                            realm.create(User.self, value: [
                                "userId": SyncUser.current!.identity!,
                                "nickname": nickname,
                                "spriteUrl": sprite!,
                                "latitude": 0,
                                "longitude": 0
                                ], update: true)
                        }
                        self?.navigationController?.pushViewController(MapViewController(), animated: true)
                    })
                } else {
                    self?.navigationController?.pushViewController(MapViewController(), animated: true)
                }
            }
            
        })
        
    }

}

