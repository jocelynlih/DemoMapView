//
//  Venue.swift
//  DemoMapView
//
//  Created by Jocelyn Harrington on 2/18/16.
//
//

import MapKit
class Venue: NSObject, MKAnnotation {
    var title:String?
    var coordinate: CLLocationCoordinate2D
    var imageURL:String?
    init(lat:Double, lng:Double, name: String) {
        coordinate = CLLocationCoordinate2DMake(lat, lng)
        title = name
        super.init()
    }
}