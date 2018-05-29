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
    
    func databaseQueue(cityId: String, complexMapInfo: [String:String]) {
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
                let rs = try database.executeQuery("select distinct IdPelicula from Cartelera where IdComplejoVista = \(complexMapInfo["idComplex"]!)", values: nil)
                while rs.next() {
                    var movieDictionary = [String: String]()
                    let movie = rs.stringForColumn("IdPelicula")
                    movieDictionary["movie"] = movie
                    do {
                        let rs = try database.executeQuery("select Titulo, Sinopsis, Actores, Director from Pelicula where Id = \(movie)", values: nil)
                        while rs.next() {
                            let title = rs.stringForColumn("Titulo")
                            let sinopsis = rs.stringForColumn("Sinopsis")
                            let actors = rs.stringForColumn("Actores")
                            let director = rs.stringForColumn("Director")
                            movieDictionary["title"] = title
                            movieDictionary["sinopsis"] = sinopsis
                            movieDictionary["actors"] = actors
                            movieDictionary["director"] = director
                        }
                    } catch let error as NSError {
                        print("failed: \(error.localizedDescription)")
                    }
                    self.billboard.append(movieDictionary)
                    print(self.billboard)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.bilboardTableView.reloadData()
                self.loaderBackgroundView.hidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            })
            
            database.close()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "MovieSegue") {
            let tabBarController = segue.destinationViewController as! UITabBarController
            let movieViewController = tabBarController.viewControllers![0] as! MovieViewController
            let galleryViewController = tabBarController.viewControllers![1] as! GalleryViewController
            let scheduleViewController = tabBarController.viewControllers![3] as! ScheduleViewController
            if self.billboard.isEmpty == false {
                movieViewController.databaseQueue(self.selectedMovie)
                galleryViewController.databaseQueue(self.cityId!, movieInfo: self.selectedMovie)
                scheduleViewController.databaseQueue(self.cityId!, movieInfo: self.selectedMovie)
                self.loaderBackgroundView.hidden = true
                self.activityIndicator.effectView.removeFromSuperview()
            }
        }
    }
    
    func triggerSegue() {
        performSegueWithIdentifier("MovieSegue", sender: nil)
    }
}

extension BillboardViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.billboard.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BillboardCell") as! BillboardTableViewCell
        let billboard = self.billboard[indexPath.row]
        self.selectedMovie = billboard as! [String : String]
        cell.billboardLabel.text = billboard.valueForKey("title") as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.loaderBackgroundView.hidden = false
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Solicitando Película...")
        let movie = self.billboard[indexPath.row]
        self.selectedMovie = movie as! [String : String]
        print("selectedMovie= \(self.selectedMovie)")
        self.triggerSegue()
    }
}
