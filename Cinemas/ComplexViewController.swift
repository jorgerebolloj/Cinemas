//
//  ComplexViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 01/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import FMDB

class ComplexViewController: UIViewController {
    @IBOutlet weak var complexTableView: UITableView!
    @IBOutlet weak var loaderBackgroundView: UIView!
    @IBOutlet weak var complexNavigationItem: UINavigationItem!
    @IBOutlet weak var complexBarButtonItem: UIBarButtonItem!
    
    var complex = [AnyObject]()
    var queue: FMDatabaseQueue?
    var cityId: String!
    var selectedComplex = [String:String]()
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Complejos"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Complejos...")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func databaseQueue(cityId: String) {
        self.cityId = cityId
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let documentDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
            let fullUrl = documentDirectory?.URLByAppendingPathComponent("\(cityId).sqlite")
            
            let database = FMDatabase(path: fullUrl!.path)
            
            if !database.open() {
                print("Unable to open database")
                return
            }
            
            do {
                let rs = try database.executeQuery("select IdComplejoVista, Nombre, Direccion, Latitud, Longitud, Telefono from Complejo", values: nil)
                while rs.next() {
                    var complexDictionary = [String: String]()
                    let idComplex = rs.stringForColumn("IdComplejoVista")
                    let name = rs.stringForColumn("Nombre")
                    let address = rs.stringForColumn("Direccion")
                    let latitude = rs.stringForColumn("Latitud")
                    let trimmedLatitude = latitude.stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )
                    let longitude = rs.stringForColumn("Longitud")
                    let trimmedLongitude = longitude.stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )
                    let telephone = rs.stringForColumn("Telefono")
                    complexDictionary["idComplex"] = idComplex
                    complexDictionary["name"] = name
                    complexDictionary["address"] = address
                    complexDictionary["latitude"] = trimmedLatitude
                    complexDictionary["longitude"] = trimmedLongitude
                    complexDictionary["telephone"] = telephone
                    self.complex.append(complexDictionary)
                    print(self.complex)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.complexTableView.reloadData()
                self.loaderBackgroundView.hidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            })
            
            database.close()
        })
    }
    
    @IBAction func shomMapAction(sender: AnyObject) {
        self.loaderBackgroundView.hidden = false
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Solicitando Mapa...")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "BillboardSegue") {
            let billboardViewController = segue.destinationViewController as! BillboardViewController
            if self.complex.isEmpty == false {
                billboardViewController.databaseQueue(self.cityId!, complexMapInfo: self.selectedComplex)
                self.loaderBackgroundView.hidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        } else if (segue.identifier == "MapSegue") {
            let mapViewController = segue.destinationViewController as! MapViewController
            if self.complex.isEmpty == false {
                mapViewController.prepareMapInfo(self.complex)
                self.loaderBackgroundView.hidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        }
    }
    
    func triggerSegue() {
        performSegueWithIdentifier("BillboardSegue", sender: nil)
    }
}

extension ComplexViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.complex.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ComplexCell") as! ComplexTableViewCell
        let complex = self.complex[indexPath.row]
        cell.complexNameLabel.text = complex.valueForKey("name") as? String
        cell.complexAddressLabel.text = complex.valueForKey("address") as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.loaderBackgroundView.hidden = false
        activityIndicator.activityIndicator("Solicitando Cartelera...")
        let complex = self.complex[indexPath.row]
        self.selectedComplex = complex as! [String : String]
        print("selectedComplex= \(self.selectedComplex)")
        self.triggerSegue()
    }
}
