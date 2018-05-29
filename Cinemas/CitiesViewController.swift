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
        
        let url = NSURL(string: Constants.apiUrlCities)
        let session = NSURLSession.sharedSession()
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let task = session.dataTaskWithURL(url!, completionHandler: {data, response, error -> Void in
                if(error != nil) {
                    print(error!.localizedDescription)
                } else {
                    let nsdata:NSData = NSData(data: data!)
                    do {
                        let jsonCompleto = try NSJSONSerialization.JSONObjectWithData(nsdata, options: NSJSONReadingOptions.MutableContainers)
                        print("Json Completo\(jsonCompleto)")
                        if let nsArrayJson = jsonCompleto as? NSArray {
                            nsArrayJson.enumerateObjectsUsingBlock({ objeto, index, stop in
                                let arrayCity = objeto as! NSDictionary
                                print("City \(index):\(arrayCity)")
                                self.saveCity(arrayCity)
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.citiesTableView.reloadData()
                                    self.loaderBackgroundView.hidden = true
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
    
    func saveCity(cityValues: NSDictionary) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity = NSEntityDescription.entityForName("City", inManagedObjectContext: managedContext)
        let city = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ComplexSegue") {
            let complexViewController = segue.destinationViewController as! ComplexViewController
            if self.cityId != nil {
                complexViewController.databaseQueue(self.cityId)
            }
        }
    }
    
    func triggerSegue() {
        performSegueWithIdentifier("ComplexSegue", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CitiesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return cities.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CityCell") as! CityTableViewCell
        let city = cities[indexPath.row]
        cell.cityLabel.text = city.valueForKey("Nombre") as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.loaderBackgroundView.hidden = false
        activityIndicator.activityIndicator("Solicitando Complejos...")
        let city = cities[indexPath.row]
        let cityId = String(city.valueForKey("Id")!)
        self.cityId = cityId
        print("CityId= \(self.cityId)")
        let url = NSURL(string: Constants.apiUrlCity + cityId)
        let downloadRequest = NSURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let task = session.downloadTaskWithRequest(downloadRequest, completionHandler: {url, response, error -> Void in
                if(error != nil) {
                    print(error!.localizedDescription)
                } else {
                    guard  let tempLocation = url where error == nil else { return }
                    let documentDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
                    let fullUrl = documentDirectory?.URLByAppendingPathComponent("\(cityId).sqlite")
                    print("Full URL SQlite file: \(fullUrl)")
                    do {
                        try NSFileManager.defaultManager().moveItemAtURL(tempLocation, toURL: fullUrl!)
                    } catch NSCocoaError.FileReadNoSuchFileError {
                        print("No such file")
                    } catch {
                        print("Error downloading file : \(error)")
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.triggerSegue()
                        self.loaderBackgroundView.hidden = true
                        self.activityIndicator.effectView.removeFromSuperview()
                    })
                }
            })
            task.resume()
        })
    }
}

