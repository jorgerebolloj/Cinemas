//
//  MapViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 01/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    @IBOutlet weak var map: MKMapView!
    
    var complexMaps = [ComplexLocation]()
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mapa de Complejos"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Mapa...")
        self.setComplexMap()
    }
    
    func prepareMapInfo(complexMapInfo: [AnyObject]) {
        print(complexMapInfo)
        
        for singleComplexMapInfo in complexMapInfo {
            let title = singleComplexMapInfo["name"] as? String! != nil ? (singleComplexMapInfo["name"] as? String)! : "S/Nombre"
            let address = singleComplexMapInfo["address"] as? String! != nil ? (singleComplexMapInfo["address"] as? String)! : "S/Dirección"
            let telephone = singleComplexMapInfo["telephone"] as? String! != nil ? (singleComplexMapInfo["telephone"] as? String)! : "S/Teléfono"
            let latitude = Double(singleComplexMapInfo["latitude"]!!.description) != nil ? Double(singleComplexMapInfo["latitude"]!!.description) : 0.0
            let longitude = Double(singleComplexMapInfo["longitude"]!!.description) != nil ? Double(singleComplexMapInfo["longitude"]!!.description) : 0.0
            let complexInfo = ComplexLocation(title: title,
                                              address: address,
                                              telephone: telephone,
                                              coordinate: CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!))
            complexMaps.append(complexInfo)
        }
    }
    
    func setComplexMap() {
        for singleComplexInfo in complexMaps {
            map.addAnnotation(singleComplexInfo)
        }
        var zoomRect = MKMapRectNull
        for annotation in map.annotations {
            let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0)
            if (MKMapRectIsNull(zoomRect)) {
                zoomRect = pointRect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, pointRect)
            }
        }
        map.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(10, 10, 10, 10), animated: true)
        self.loaderBackgroundView.hidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        let subtitleView = UILabel()
        subtitleView.textColor = UIColor(red:0.00, green:0.35, blue:0.64, alpha:1.0)
        subtitleView.font = subtitleView.font.fontWithSize(12)
        subtitleView.numberOfLines = 0
        subtitleView.text = annotation.subtitle!
        pinView!.detailCalloutAccessoryView = subtitleView
        pinView?.pinTintColor = UIColor(red:0.00, green:0.35, blue:0.64, alpha:1.0)
        
        return pinView
    }
}

