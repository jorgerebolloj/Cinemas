//
//  CitiesViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 31/05/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import CoreData

class CitiesViewController: UIViewController {
    @IBOutlet weak var citiesTableView: UITableView!
    @IBOutlet weak var loaderBackgroundView: UIView!
    
    var cities = [NSManagedObject]()
    var cityId:String!
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ciudades"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Ciudades...")
        
        let url = URL(string: Constants.apiUrlCities)
        let session = URLSession.shared
        
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            let task = session.dataTask(with: url!, completionHandler: {data, response, error -> Void in
                if(error != nil) {
                    print(error!.localizedDescription)
                } else {
                    let nsdata:Data = NSData(data: data!) as Data
                    do {
                        let jsonCompleto = try JSONSerialization.jsonObject(with: nsdata, options: JSONSerialization.ReadingOptions.mutableContainers)
                        print("Json Completo\(jsonCompleto)")
                        if let nsArrayJson = jsonCompleto as? NSArray {
                            nsArrayJson.enumerateObjects({ objeto, index, stop in
                                let arrayCity = objeto as! NSDictionary
                                print("City \(index):\(arrayCity)")
                                self.saveCity(arrayCity)
                                
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.citiesTableView.reloadData()
                                    self.loaderBackgroundView.isHidden = true
                                    self.activityIndicator.effectView.removeFromSuperview()
                                })
                            })
                        }
                    } catch {
                        print("Error al serializar Json")
                    }
                }
            })
            task.resume()
        })
    }
    
    func saveCity(_ cityValues: NSDictionary) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: "City", in: managedContext)
        let city = NSManagedObject(entity: entity!, insertInto: managedContext)
        city.setValue(cityValues["Estado"], forKey: "estado")
        city.setValue(cityValues["Id"], forKey: "id")
        city.setValue(cityValues["IdEstado"], forKey: "idEstado")
        city.setValue(cityValues["IdPais"], forKey: "idPais")
        city.setValue(cityValues["Latitud"], forKey: "latitud")
        city.setValue(cityValues["Longitud"], forKey: "longitud")
        city.setValue(cityValues["Nombre"], forKey: "nombre")
        city.setValue(cityValues["Pais"], forKey: "pais")
        
        do {
            try managedContext.save()
            cities.append(city)
        } catch let error as NSError {
            print("No hemos podido persistir debido al error \(error), \(error.userInfo)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "ComplexSegue") {
            let complexViewController = segue.destination as! ComplexViewController
            if self.cityId != nil {
                complexViewController.databaseQueue(self.cityId)
            }
        }
    }
    
    func triggerSegue() {
        performSegue(withIdentifier: "ComplexSegue", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CitiesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell") as! CityTableViewCell
        let city = cities[indexPath.row]
        cell.cityLabel.text = city.value(forKey: "Nombre") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.loaderBackgroundView.isHidden = false
        activityIndicator.activityIndicator("Solicitando Complejos...")
        let city = cities[indexPath.row]
        let cityId = String(describing: city.value(forKey: "Id")!)
        self.cityId = cityId
        print("CityId= \(self.cityId)")
        let url = URL(string: Constants.apiUrlCity + cityId)
        let downloadRequest = URLRequest(url: url!)
        let session = URLSession.shared
        
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            let task = session.downloadTask(with: downloadRequest, completionHandler: {url, response, error -> Void in
                if(error != nil) {
                    print(error!.localizedDescription)
                } else {
                    guard  let tempLocation = url, error == nil else { return }
                    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                    let fullUrl = documentDirectory?.appendingPathComponent("\(cityId).sqlite")
                    print("Full URL SQlite file: \(fullUrl)")
                    do {
                        try FileManager.default.moveItem(at: tempLocation, to: fullUrl!)
                    } catch CocoaError.fileReadNoSuchFile {
                        print("No such file")
                    } catch {
                        print("Error downloading file : \(error)")
                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.triggerSegue()
                        self.loaderBackgroundView.isHidden = true
                        self.activityIndicator.effectView.removeFromSuperview()
                    })
                }
            })
            task.resume()
        })
    }
}

