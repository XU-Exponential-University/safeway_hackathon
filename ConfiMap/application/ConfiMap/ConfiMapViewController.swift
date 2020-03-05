//
//  ConfiMapViewController.swift
//  ConfiMap
//
//  Created by Andreas Schmidt on 11.12.19.
//  Copyright © 2019 Andreas Schmidt. All rights reserved.
//

import UIKit
import MapKit
import SFProgressCircle

class ConfiMapViewController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var shopViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var sosContainerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var closeICon: UIImageView!
    @IBOutlet var hintContainerView: UIView!
    
    @IBOutlet var imgNextSafeSpot: UIImageView!
    @IBOutlet var imgShop: UIImageView!
    @IBOutlet var imgSOS: UIImageView!
    
    @IBOutlet var overlayView: UIView!
    
    @IBOutlet var progressCircle: SFCircleGradientView!
    @IBOutlet var countdown: UILabel!
    
    var timer: Timer?
    
    var counter = 0
    
    var progress = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overlayView.isHidden = true
        
        self.mapView.delegate = self
        let filter = MKPointOfInterestFilter(including: [])
        self.mapView.pointOfInterestFilter = filter
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.createMapAnnotations()
        
        let closeGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.closeSheet))
        self.closeICon.addGestureRecognizer(closeGestureRecognizer)
        
        let openGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openSheet))
        self.imgNextSafeSpot.addGestureRecognizer(openGestureRecognizer)
        
        let sosGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.sosTapped))
        self.imgSOS.addGestureRecognizer(sosGestureRecognizer)
        
        let closeOverlayGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideSOS))
        self.overlayView.addGestureRecognizer(closeOverlayGestureRecognizer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.locateMe(self)
    }
    
    func createMapAnnotations() {
        // user
        let user = UserLocation()
        user.coordinate = CLLocationCoordinate2DMake(52.521881, 13.412769)
        self.mapView.addAnnotation(user)
        
        // Ten safe points
        let p1 = SafePoint()
        p1.coordinate = CLLocationCoordinate2DMake(52.522181, 13.412869)
        self.mapView.addAnnotation(p1)
        
        let p2 = SafePoint()
        p2.coordinate = CLLocationCoordinate2DMake(52.521581, 13.412169)
        self.mapView.addAnnotation(p2)
        
        let p3 = SafePoint()
        p3.coordinate = CLLocationCoordinate2DMake(52.522281, 13.413169)
        self.mapView.addAnnotation(p3)
        
        let p4 = SafePoint()
        p4.coordinate = CLLocationCoordinate2DMake(52.520020, 13.412869)
        self.mapView.addAnnotation(p4)
        
        let p5 = SafePoint()
        p5.coordinate = CLLocationCoordinate2DMake(52.521681, 13.412069)
        self.mapView.addAnnotation(p5)
        
        let p6 = SafePoint()
        p6.coordinate = CLLocationCoordinate2DMake(52.522981, 13.413569)
        self.mapView.addAnnotation(p6)
        
        let p7 = SafePoint()
        p7.coordinate = CLLocationCoordinate2DMake(52.521081, 13.413969)
        self.mapView.addAnnotation(p7)
        
        let p8 = SafePoint()
        p8.coordinate = CLLocationCoordinate2DMake(52.521481, 13.411569)
        self.mapView.addAnnotation(p8)
        
        let p9 = SafePoint()
        p9.coordinate = CLLocationCoordinate2DMake(52.521081, 13.411769)
        self.mapView.addAnnotation(p9)
        
        let p10 = SafePoint()
        p10.coordinate = CLLocationCoordinate2DMake(52.520981, 13.411169)
        self.mapView.addAnnotation(p10)
        
        // Two police stations
        let police1 = Police()
        police1.coordinate = CLLocationCoordinate2DMake(52.522581, 13.414269)
        self.mapView.addAnnotation(police1)
        
        let police2 = Police()
        police2.coordinate = CLLocationCoordinate2DMake(52.519981, 13.411169)
        self.mapView.addAnnotation(police2)
    }
    
    @objc func hideSOS() {
        self.overlayView.isHidden = true
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func closeSheet() {
        self.shopViewBottomConstraint.constant = -262
        self.sosContainerBottomConstraint.constant = 96
        
        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
                        self?.hintContainerView.isHidden = false
                        self?.imgNextSafeSpot.isHidden = false
                        self?.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(52.521881, 13.412769), latitudinalMeters: 180, longitudinalMeters: 300)
            }, completion: { [weak self] _ in
                self?.mapView.deselectAnnotation(nil, animated: false)
            }
        )
    }
    
    @objc func openSheet() {
        for annotation in self.mapView.annotations where annotation is SafePoint && annotation.coordinate.latitude == 52.522181 {
            self.mapView.selectAnnotation(annotation, animated: false)
            return
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.hideSOS()
    }
    
    @IBAction func callAction(_ sender: Any) {
        self.hideSOS()
    }
    
    @objc func sosTapped() {
        if self.overlayView.isHidden {
            self.progress = 1
            self.countdown.text = "20"
            self.progressCircle.setProgress(CGFloat(self.progress), animateWithDuration: 0)
            self.progressCircle.endColor = UIColor.green
            self.progressCircle.startColor = UIColor.red
            self.progressCircle.lineWidth = 8
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] _ in
                
                if (self?.progress ?? 1) <= 0 {
                    self?.hideSOS()
                }
                
                self?.progress = (self?.progress ?? 1) - 0.05
                let valueInSeconds = (self?.progress ?? 1) * 100 / 5
                self?.countdown.text = String(format: "%d", Int(valueInSeconds))
                self?.progressCircle.setProgress(CGFloat(self?.progress ?? 1), animateWithDuration: 1)
                
            })
            self.overlayView.isHidden = false
        }
    }
    
    @IBAction func locateMe(_ sender: Any) {
        // Bln Alexanderplatz
        UIView.animate(withDuration: 0.3,
                       animations: { [weak self] in
                        self?.mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(52.521881, 13.412769), latitudinalMeters: 180, longitudinalMeters: 300)
            }, completion: nil)
        
    }
}

extension ConfiMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is SafePoint {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "safe_spot")
            annotationView.image = UIImage(named: "safe_spot")
            return annotationView
        } else if annotation is Police {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "police")
            annotationView.image = UIImage(named: "police")
            return annotationView
        } else if annotation is UserLocation {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "user")
            annotationView.image = UIImage(named: "user_location")
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is SafePoint {
            var imgname = "lateshop"
            switch  counter {
            case 0:
                imgname = "lateshop"
            case 1:
                imgname = "lateshop2"
            case 2:
                imgname = "lateshop3"
            default:
                counter = 0
            }
            
            counter += 1

            self.imgShop.image = UIImage.init(named: imgname)
            
            self.shopViewBottomConstraint.constant = 0
            self.sosContainerBottomConstraint.constant = 262
            view.frame.size.width = view.frame.size.width * 2
            view.frame.size.height = view.frame.size.height * 2
            UIView.animate(withDuration: 0.3,
                           animations: { [weak self] in
                            if let coordinate = view.annotation?.coordinate {
                                let centerWithOffset = CLLocationCoordinate2DMake(coordinate.latitude - 0.001, coordinate.longitude)
                                self?.mapView.region = MKCoordinateRegion(center: centerWithOffset, latitudinalMeters: 180, longitudinalMeters: 300)
                            }
                            self?.view.layoutIfNeeded()
                            self?.hintContainerView.isHidden = true
                            self?.imgNextSafeSpot.isHidden = true
                }, completion: nil)
        } else if view.annotation is Police {
            // tbd.
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        if view.annotation is SafePoint {
            view.frame.size.width = view.frame.size.width / 2
            view.frame.size.height = view.frame.size.height / 2
        }
    }
}


