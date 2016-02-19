//
//  ViewController.swift
//  DemoMapView
//
//  Created by Jocelyn Harrington on 2/18/16.
//
//

import UIKit
import MapKit
import CoreLocation
class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var venueList:[Venue] = []
    var locationManager: CLLocationManager? = nil
    var userLocation: CLLocation?
    @IBOutlet var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startUpdateLocation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopUpdateLocation()
        self.clearWaypoints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func startUpdateLocation() {
        if CLLocationManager.locationServicesEnabled() {
            if locationManager == nil {
                locationManager = CLLocationManager()
                locationManager!.delegate = self
                locationManager!.desiredAccuracy = kCLLocationAccuracyBest
                locationManager!.distanceFilter = 10
                if locationManager!.respondsToSelector("requestWhenInUseAuthorization") {
                    locationManager!.requestAlwaysAuthorization()
                }
                locationManager!.startUpdatingLocation()
            }
        }
    }
    
    func stopUpdateLocation() {
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
            locationManager = nil
        }
    }
    
    func getVenues() {
        let parser = VenueFetchParser()
        if let currentLocation = self.userLocation {
            parser.getFoursqData(currentLocation, venueCompletionHandler:{ (venues) -> Void in
                self.showWaypoints(venues)
                }
            )
        }
    }
    
    func clearWaypoints() {
        if mapView?.annotations != nil {
            mapView.removeAnnotations(mapView.annotations as [MKAnnotation])
        }
        self.venueList = []
    }
    
    func showWaypoints(waypoints:[Venue]) {
        self.venueList = waypoints
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView?.addAnnotations(self.venueList)
            self.mapView?.showAnnotations(self.venueList, animated: true)
        })
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let currentLocation:CLLocation? = locations.last
        
        if currentLocation != nil  && currentLocation!.horizontalAccuracy > 0 {
            self.userLocation = currentLocation!
            if let mapView = self.mapView {
                let currentCoord = currentLocation!.coordinate
                let span = MKCoordinateSpanMake(0.01, 0.01)
                let region = MKCoordinateRegionMake(currentCoord, span)
                mapView.setRegion(region, animated: true)
            }
            if self.venueList.isEmpty {
                self.getVenues()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            if locationManager!.respondsToSelector("requestWhenInUseAuthorization") {
                locationManager!.requestWhenInUseAuthorization()
            }
        default:
            break
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("VenueWayPoint")
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "VenueWayPoint")
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }

        if let waypoint = annotation as? Venue {
            if waypoint.imageURL != nil {
                view!.leftCalloutAccessoryView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            }
        }
        return view
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let waypoint = view.annotation as? Venue {
            if let thumbnailImageView = view.leftCalloutAccessoryView as? UIImageView {
                if let imageURLPath = waypoint.imageURL {
                    NSURLSession.sharedSession().dataTaskWithRequest(
                        NSURLRequest(URL: NSURL (string: imageURLPath)!),
                        completionHandler: { (data, response, error) -> Void in
                            if let e = error {
                                print(e)
                            } else if let imageData = data {
                                if let image = UIImage(data: imageData) {
                                    thumbnailImageView.image = image
                                }
                            }
                    }).resume()
                }
            }
        }
    }
}

