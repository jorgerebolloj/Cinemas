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
    
    func databaseQueue(_ cityId: String) {
        self.cityId = cityId
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fullUrl = documentDirectory?.appendingPathComponent("\(cityId).sqlite")
            
            let database = FMDatabase(path: fullUrl!.path)
            
            if !database.open() {
                print("Unable to open database")
                return
            }
            
            do {
                let rs = try database.executeQuery("select IdComplejoVista, Nombre, Direccion, Latitud, Longitud, Telefono from Complejo", values: nil)
                while rs.next() {
                    var complexDictionary = [String: String]()
                    let idComplex = rs.string(forColumn: "IdComplejoVista")
                    let name = rs.string(forColumn: "Nombre")
                    let address = rs.string(forColumn: "Direccion")
                    let latitude = rs.string(forColumn: "Latitud")
                    let trimmedLatitude = latitude?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let longitude = rs.string(forColumn: "Longitud")
                    let trimmedLongitude = longitude?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let telephone = rs.string(forColumn: "Telefono")
                    complexDictionary["idComplex"] = idComplex
                    complexDictionary["name"] = name
                    complexDictionary["address"] = address
                    complexDictionary["latitude"] = trimmedLatitude
                    complexDictionary["longitude"] = trimmedLongitude
                    complexDictionary["telephone"] = telephone
                    self.complex.append(complexDictionary as AnyObject)
                    print(self.complex)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.complexTableView.reloadData()
                self.loaderBackgroundView.isHidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            })
            
            database.close()
        })
    }
    
    @IBAction func shomMapAction(_ sender: AnyObject) {
        self.loaderBackgroundView.isHidden = false
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Solicitando Mapa...")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "BillboardSegue") {
            let billboardViewController = segue.destination as! BillboardViewController
            if self.complex.isEmpty == false {
                billboardViewController.databaseQueue(self.cityId!, complexMapInfo: self.selectedComplex)
                self.loaderBackgroundView.isHidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        } else if (segue.identifier == "MapSegue") {
            let mapViewController = segue.destination as! MapViewController
            if self.complex.isEmpty == false {
                mapViewController.prepareMapInfo(self.complex)
                self.loaderBackgroundView.isHidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        }
    }
    
    func triggerSegue() {
        performSegue(withIdentifier: "BillboardSegue", sender: nil)
    }
}

extension ComplexViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.complex.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ComplexCell") as! ComplexTableViewCell
        let complex = self.complex[indexPath.row]
        cell.complexNameLabel.text = complex.value(forKey: "name") as? String
        cell.complexAddressLabel.text = complex.value(forKey: "address") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.loaderBackgroundView.isHidden = false
        activityIndicator.activityIndicator("Solicitando Cartelera...")
        let complex = self.complex[indexPath.row]
        self.selectedComplex = complex as! [String : String]
        print("selectedComplex= \(self.selectedComplex)")
        self.triggerSegue()
    }
}
