//
//  MapViewController.swift
//  YorHa
//
//  Created by Maximilian Alexander on 3/12/18.
//  Copyright © 2018 Maximilian Alexander. All rights reserved.
//

import UIKit
import MapKit
import Proposer
import Cartography
import RealmSwift
import MessageViewController

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    lazy var mapView: MKMapView =  {
        let m = MKMapView()
        return m
    }()
    
    lazy var centerMeButton: UIButton = {
        let b = UIButton()
        b.backgroundColor = Constants.Colors.primaryColor
        b.layer.cornerRadius = 36 / 2
        b.layer.masksToBounds = true
        b.setImage(UIImage(named: "center_me")?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        b.imageView?.contentMode = .scaleAspectFit
        b.tintColor = .white
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 2.0
        return b
    }()
    
    lazy var thoughtButton: UIButton = {
        let b = UIButton()
        b.backgroundColor = Constants.Colors.primaryColor
        b.layer.cornerRadius = 36 / 2
        b.layer.masksToBounds = true
        b.setImage(UIImage(named: "thought")?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        b.imageView?.contentMode = .scaleAspectFit
        b.tintColor = .white
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 2.0
        return b
    }()
    
    var userAnnotations: [String: UserAnnotation] = [:]
    var token: NotificationToken?
    let locationManager = CLLocationManager()
    let realm = Realm.main

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "YorHa"

        
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
        view.addSubview(mapView)
        view.addSubview(centerMeButton)
        view.addSubview(thoughtButton)
        
        constrain(mapView, centerMeButton, thoughtButton) { (mapView, centerMeButton, thoughtButton) in
            mapView.left == mapView.superview!.left
            mapView.top == mapView.superview!.top
            mapView.bottom == mapView.superview!.bottom
            mapView.right == mapView.superview!.right
            
            centerMeButton.left == centerMeButton.superview!.left + 16
            centerMeButton.bottom == centerMeButton.superview!.safeAreaLayoutGuide.bottom - 16
            centerMeButton.height == 36
            centerMeButton.width == 36
            
            thoughtButton.right == thoughtButton.superview!.right - 16
            thoughtButton.bottom == thoughtButton.superview!.safeAreaLayoutGuide.bottom - 16
            thoughtButton.height == 36
            thoughtButton.width == 36
        }
        
        mapView.delegate = self
        locationManager.delegate = self
        
        centerMeButton.addTarget(self, action: #selector(centerMeButtonDidClick), for: .touchUpInside)
        thoughtButton.addTarget(self, action: #selector(thoughtButtonDidClick), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(attemptLogout))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Change Sprite", style: .plain, target: self, action: #selector(changeSpriteButtonDidClick))
        
        token = realm.objects(User.self).observe { [weak self] (changes) in
            guard let `self` = self else { return }
            
            switch changes {
            case .initial(let results):
                
                // Results are now populated and can be accessed without blocking the UI
                results.forEach({ (user) in
                    let userAnnotation = UserAnnotation(user: user)
                    self.mapView.addAnnotation(userAnnotation)
                    self.userAnnotations[user.userId] = userAnnotation
                })
                
                self.centerMeButtonDidClick()
                
            case .update(let results, let deletions, let insertions, let modifications):
                
                let usersInserted = insertions.map({ results[$0] })
                usersInserted.forEach({ (user) in
                    let userAnnotation = UserAnnotation(user: user)
                    self.mapView.addAnnotation(userAnnotation)
                    self.userAnnotations[user.userId] = userAnnotation
                })
                
                let userIdsDeleted = deletions.map({ results[$0].userId })
                
                userIdsDeleted.forEach({ (userId) in
                    self.mapView.removeAnnotation(self.userAnnotations[userId]!)
                    self.userAnnotations.removeValue(forKey: userId)
                })
                
                let usersModified = modifications.map({ results[$0] })
                usersModified.forEach({ (user) in
                    guard let userAnnotation = self.userAnnotations[user.userId] else { return }
                    userAnnotation.animateCoordinate(coordinate: CLLocationCoordinate2DMake(user.latitude, user.longitude))
                    guard let view = self.mapView.view(for: userAnnotation) as? UserAnnotationView else { return }
                    view.annotation = userAnnotation
                })
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(error as! String)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let location: PrivateResource = .location(.whenInUse)
        let propose: Propose = {
            proposeToAccess(location, agreed: {
                
            }, rejected: { [weak self] in
                guard let `self` = self else { return }
                let alert = UIAlertController(title: "Need location permissions!", message: "You will need location permissions for YorHa to work.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                    if let url = NSURL(string: UIApplicationOpenSettingsURLString) as URL? {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            })
        }
        propose()
    }
    
    @objc func centerMeButtonDidClick() {
        guard let me = realm.object(ofType: User.self, forPrimaryKey: SyncUser.current!.identity!) else { return }
        let coord = CLLocationCoordinate2DMake(me.latitude, me.longitude)
        self.mapView.setCenter(coord, animated: true)
    }
    
    @objc func thoughtButtonDidClick() {
        let thoughtViewController = UINavigationController(rootViewController: PostThoughtViewController())
        present(thoughtViewController, animated: true, completion: nil)
    }
    
    @objc func changeSpriteButtonDidClick() {
        let changeSpritesViewController = UINavigationController(rootViewController: SpritesViewController())
        self.present(changeSpritesViewController, animated: true, completion: nil)
    }
    
    @objc func attemptLogout() {
        let alert = UIAlertController(title: "Logout?", message: "Are you sure you want to logout?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            
        }))
        alert.addAction(UIAlertAction(title: "Yes, Logout", style: .destructive, handler: { [weak self] (_) in
            SyncUser.current?.logOut()
            self?.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? UserAnnotation {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: UserAnnotationView.ReuseId) {
                annotationView.annotation = annotation
                return annotationView
            }else {
                let annotationView = UserAnnotationView(annotation: annotation)
                return annotationView
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let userAnnotation = view.annotation as? UserAnnotation else { return }
        let thoughtsList = UINavigationController(rootViewController: ThoughtsListViewController(user: userAnnotation.user))
        present(thoughtsList, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            // The user accepted authorization
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations[0].coordinate
        guard let myUser = SyncUser.current?.identity else { return  }
        guard let me = realm.object(ofType: User.self, forPrimaryKey: myUser) else { return }
        try! realm.write {
            me.latitude = coord.latitude
            me.longitude = coord.longitude
            me.lastSeenTimestamp = Date()
        }
    }

}
