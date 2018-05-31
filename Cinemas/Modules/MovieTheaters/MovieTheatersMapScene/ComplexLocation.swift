//
//  ComplexLocation.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 01/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import Foundation
import MapKit

class ComplexLocation: NSObject, MKAnnotation {
    let title: String?
    let address: String
    let telephone: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, address: String, telephone: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.address = address
        self.telephone = telephone
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        let complexDescription = "\(address) \n \(telephone)"
        return complexDescription
    }
}