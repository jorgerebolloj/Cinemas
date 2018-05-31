//
//  BillboardViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import FMDB

class BillboardViewController: UIViewController {
    @IBOutlet weak var bilboardTableView: UITableView!
    @IBOutlet weak var loaderBackgroundView: UIView!
    
    var billboard = [AnyObject]()
    var queue: FMDatabaseQueue?
    var cityId: String!
    var selectedMovie = [String:String]()
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cartelera"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Cartelera...")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func databaseQueue(_ cityId: String, complexMapInfo: [String:String]) {
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
                let rs = try database.executeQuery("select distinct IdPelicula from Cartelera where IdComplejoVista = \(complexMapInfo["idComplex"]!)", values: nil)
                while rs.next() {
                    var movieDictionary = [String: String]()
                    let movie = rs.string(forColumn: "IdPelicula")
                    movieDictionary["movie"] = movie
                    do {
                        let rs = try database.executeQuery("select Titulo, Sinopsis, Actores, Director from Pelicula where Id = \(movie)", values: nil)
                        while rs.next() {
                            let title = rs.string(forColumn: "Titulo")
                            let sinopsis = rs.string(forColumn: "Sinopsis")
                            let actors = rs.string(forColumn: "Actores")
                            let director = rs.string(forColumn: "Director")
                            movieDictionary["title"] = title
                            movieDictionary["sinopsis"] = sinopsis
                            movieDictionary["actors"] = actors
                            movieDictionary["director"] = director
                        }
                    } catch let error as NSError {
                        print("failed: \(error.localizedDescription)")
                    }
                    self.billboard.append(movieDictionary as AnyObject)
                    print(self.billboard)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.bilboardTableView.reloadData()
                self.loaderBackgroundView.isHidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            })
            
            database.close()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "MovieSegue") {
            let tabBarController = segue.destination as! UITabBarController
            let movieViewController = tabBarController.viewControllers![0] as! MovieViewController
            let galleryViewController = tabBarController.viewControllers![1] as! GalleryViewController
            let scheduleViewController = tabBarController.viewControllers![3] as! ScheduleViewController
            if self.billboard.isEmpty == false {
                movieViewController.databaseQueue(self.selectedMovie)
                galleryViewController.databaseQueue(self.cityId!, movieInfo: self.selectedMovie)
                scheduleViewController.databaseQueue(self.cityId!, movieInfo: self.selectedMovie)
                self.loaderBackgroundView.isHidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        }
    }
    
    func triggerSegue() {
        performSegue(withIdentifier: "MovieSegue", sender: nil)
    }
}

extension BillboardViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.billboard.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BillboardCell") as! BillboardTableViewCell
        let billboard = self.billboard[indexPath.row]
        self.selectedMovie = billboard as! [String : String]
        cell.billboardLabel.text = billboard.value(forKey: "title") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.loaderBackgroundView.isHidden = false
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Solicitando Película...")
        let movie = self.billboard[indexPath.row]
        self.selectedMovie = movie as! [String : String]
        print("selectedMovie= \(self.selectedMovie)")
        self.triggerSegue()
    }
}
