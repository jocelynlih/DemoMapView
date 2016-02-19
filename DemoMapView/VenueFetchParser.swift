//
//  VenueParser.swift
//  DemoMapView
//
//  Created by Jocelyn Harrington on 2/18/16.
//
//

import Foundation
import CoreLocation

struct VenueFetchParser {
    enum JSONError: String, ErrorType {
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    typealias VenueCompletionHandler = ([Venue]) -> Void
    func getFoursqData(currentLocation:CLLocation, venueCompletionHandler:VenueCompletionHandler) {
        if let endpoint:String = self.getEndPoint(currentLocation) {
            if let url:NSURL = NSURL(string: endpoint) {
                let session = NSURLSession.sharedSession()
                
                let task = session.dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
                    if error != nil {
                        print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    }
                    else if data != nil {
                        let venueList:[Venue] = self.parseVenueData(data!)
                        venueCompletionHandler(venueList)
                    }
                })
                task.resume()
            }
        }
        
    }
    
    func getEndPoint(currentLocation:CLLocation) -> String {
        let endpoint = "https://api.foursquare.com/v2/venues/explore?ll=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&client_id=\(ClientID)&client_secret=\(ClientSecret)&v=20160218"
        return endpoint
    }
    
    func parseVenueData(data:NSData) -> [Venue] {
        var venueList:[Venue] = []
        do {
            guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? NSDictionary else { throw JSONError.ConversionFailed }
            if let response = json["response"] as? [String: AnyObject],
                let groups = response["groups"] as? [AnyObject],
                let itemsDict = groups[0] as? [String: AnyObject],
                let items = itemsDict["items"] as? [[String: AnyObject]]
            {
                for item:[String:AnyObject] in items {
                    if let venueDict = item["venue"] as? [String: AnyObject]
                    {
                        
                        if let location = venueDict["location"] as? [String: AnyObject],
                            let name = venueDict["name"] as? String
                        {
                            let lat:Double = Double(location["lat"] as! NSNumber)
                            let lng:Double = Double(location["lng"] as! NSNumber)
                            let venue:Venue = Venue(lat: lat, lng: lng, name: name)
                            if let photosDict = venueDict["photos"] as? [String: AnyObject],
                                let photos = photosDict["groups"] as? [AnyObject]
                            {
                                if !photos.isEmpty {
                                    venue.imageURL = photos[0] as? String
                                }
                            }
                            venueList.append(venue)
                        }
                    }
                }
            }
            
        } catch let error as JSONError {
            print(error.rawValue)
        } catch {
            print(error)
        }
        
        return venueList
    }
}