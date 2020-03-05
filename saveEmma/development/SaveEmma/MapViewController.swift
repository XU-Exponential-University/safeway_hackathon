//
//  MapViewController.swift
//  SaveEmma
//
//  Created by Schwandt, Manuel (000) on 11.12.19.
//  Copyright © 2019 Manuel Schwandt. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var restingLocationView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var route: MKRoute?
    let allowedDistance = 10.0
    let geofenceDistance = 0.0
    var userIsInSafeRegion = false
    var sourceLocation: CLLocationCoordinate2D?
    var predefinedRoute: MKRoute?
    
    // Hard coded locations
    let destinationLocation = CLLocation(latitude: 52.3918, longitude: 13.1227)
    let school = CLLocation(latitude: 52.3890, longitude: 13.1195)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get required permissions to request location
        checkLocationAuthorizationStatus()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Set up the locationManager delegate to receive locationManager locations
        locationManager.delegate = self
                
        // Set up the mapView delegate to show routing lines later
        mapView.delegate = self
        
        // Start location updates
        if CLLocationManager.locationServicesEnabled() {
            // We can request the user's location - show it on the map and start updating the user's location
            startMonitoringGeoFence(location: school, radius: 100.0)
            startTrackingLocation()
        }
    }
    
    func showRestingLocationView(display: Bool) {
        UIView.animate(withDuration: 0.5) {
            if display {
                self.restingLocationView.alpha = 1.0
            }
            else {
                self.restingLocationView.alpha = 0.0
            }
        }
    }
    
    func showAlertView(display: Bool) {
        UIView.animate(withDuration: 0.5) {
            if display {
                self.alertView.alpha = 1.0
            }
            else {
                self.alertView.alpha = 0.0
            }
        }
    }
    
    func startMonitoringGeoFence(location: CLLocation, radius: Float) {
        // We can request the user's location - start monitoring for geofence
        locationManager.startMonitoring(for: region(location: location, radius: radius))
    }
    
    func startTrackingLocation() {
        mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 500
        
        mapView.setRegion(MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius), animated: true)
    }
    
    func checkLocationAuthorizationStatus() {
      if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
        // User allowed us to request his location. You might want to react to that here.
        
      } else {
        locationManager.requestWhenInUseAuthorization()
      }
    }
    
    func startRouteNavigation(destination: CLLocation) {
        // TO DO
    }
    
    // MARK: - Show route navigation
    
    //Calculate the route - This is not necessary if a route is defined by the parents later
    func calculateSegmentDirections(source: CLLocation, destination: CLLocation) {
        let sourcePlacemark = MKPlacemark(coordinate: source.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate)

        // Builde the direction request
        let request = MKDirections.Request()
        request.source = MKMapItem.init(placemark: sourcePlacemark)
        request.destination = MKMapItem.init(placemark: destinationPlacemark)
        request.requestsAlternateRoutes = false
        request.transportType = .walking
      
        let directions = MKDirections(request: request)
        directions.calculate { (response: MKDirections.Response?, error: Error?) in
            if let routeResponse = response?.routes {
                // A route was calculated successfully
                
                // For demo purpose - store the first calculated route as predefined route
                if self.predefinedRoute == nil {
                    self.predefinedRoute = routeResponse.first!
                }
                
                self.route = routeResponse.first!
                self.drawRouteOnMap(route: routeResponse.first!)
            }
            
            else if let _ = error {
                // Could not calculate a route
            }
        }
    }
    
    func drawRouteOnMap(route: MKRoute) {
        // Remove existing routes
        mapView.removeOverlays(mapView.overlays)
        
        mapView.addOverlay(route.polyline)
    }
    
    func checkIfUserLeftRoute(route: MKRoute) {
        //Make sure we have a location
        if let userLocation = locationManager.location {
        
            // Get the coordinates of the route
            var coordinates: [CLLocationCoordinate2D] {
                var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: route.polyline.pointCount)
                route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: route.polyline.pointCount))
                
                return coords
            }
            
        var wrongWay = true

            for coordinate in coordinates {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = userLocation.distance(from: location)

                if (distance <= allowedDistance) {
                    // Our user has not left the predefined way
                    wrongWay = false
                }
            }
            
            if wrongWay {
                print("Kid on the wrong way")
                // Recalculate our route
                calculateSegmentDirections(source: userLocation, destination: destinationLocation)
                                   
                // Warn the kid
                self.showAlertView(display: true)
                                   
                //TO DO: Trigger parent notification
            }
            else {
                print("Kid on the right way")
                self.showAlertView(display: false)
            }
        }
    }
    
    // MARK: - Geofencing
    func region(location: CLLocation, radius: Float) -> CLCircularRegion {
        let region = CLCircularRegion(center: location.coordinate, radius: geofenceDistance, identifier: "school")
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
      return region
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.first {
            // Check if user is in a safe location
            if userLocation.distance(from: school) > geofenceDistance {
                userIsInSafeRegion = false
            }
            else {
                userIsInSafeRegion = true
                if self.restingLocationView.alpha == 0.0 {
                    self.showRestingLocationView(display: true)
                    self.showAlertView(display: false)
                }
            }
            
            // We require navigation
            
            // Center map on user
            print("Updating location to: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            centerMapOnLocation(location: userLocation)
            
            
            if (self.mapView.overlays.count > 0) {
                // We can be sure that we have a route because we've drawn it on the map
                checkIfUserLeftRoute(route: self.predefinedRoute!)
            }
            else {
                calculateSegmentDirections(source: userLocation, destination: destinationLocation)
            }
            
            if !userIsInSafeRegion {
                self.showRestingLocationView(display: false)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region")
        
        showRestingLocationView(display: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region")
        
        showRestingLocationView(display: false)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 51.0/255.0, green: 156.0/255.0, blue: 255.0/255.0, alpha: 0.8)
        renderer.lineWidth = 8.0
        
        return renderer
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
