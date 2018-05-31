//
//  ScheduleViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import CoreData
import FMDB
import Social

class ScheduleViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    @IBOutlet weak var scheduleTableView: UITableView!
    
    var times = [AnyObject]()
    var queue: FMDatabaseQueue?
    var cityId: String!
    var movieInfo = [String:String]()
    let activityIndicator = ActivityIndicator()
    var todayString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Horarios"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Horarios...")
        
        //model validation
        /*var count = 0
        for time in self.times {
            let timeValue = String(time.valueForKey("time")!)
            let roomValue = String(time.valueForKey("room")!)
            print("Cell: \(count) Horario: \(timeValue), Sala: \(roomValue)")
            count = count + 1
        }
        print("Total counts: \(times.count)")*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.navigationItem.title = "Horarios"
        self.loaderBackgroundView.isHidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func databaseQueue(_ cityId: String, movieInfo: [String:String]) {
        let todaysDate:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.todayString = dateFormatter.string(from: todaysDate)
        
        self.cityId = cityId
        self.movieInfo = movieInfo
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
            
            let queryString = "select Horario, Sala from Cartelera where IdPelicula = \(self.movieInfo["movie"]!) and Fecha = '\(self.todayString!)'  order by Sala"
            print(queryString)
            
            do {
                let rs = try database.executeQuery(queryString, values: nil)
                while rs.next() {
                    var timesDictionary = [String: String]()
                    let time = rs.string(forColumn: "Horario")
                    let room = rs.string(forColumn: "Sala")
                    timesDictionary["time"] = time
                    timesDictionary["room"] = room
                    self.times.append(timesDictionary as AnyObject)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            database.close()
        })
    }
}

extension ScheduleViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.times.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)
        //let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleCell", forIndexPath: indexPath) as! ScheduleTableViewCell
        let timeInfo = self.times[indexPath.row]
        cell.textLabel?.text = "Horario: \(timeInfo["time"]!) hrs. Sala: \(timeInfo["room"]!)"
        cell.textLabel?.textColor = UIColor(red: 253/255.0, green: 184/255.0, blue: 39/255.0, alpha: 1.0)
        cell.textLabel?.font = UIFont(name:"System-Bold", size: 17.0)
        /*cell.scheduleLabel?.text = "Horario: \(timeInfo["time"]!)"
        cell.roomLabel?.text = "Sala: \(timeInfo["room"]!)"*/
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeInfo = self.times[indexPath.row]
        print("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
        let actionSheet = UIAlertController(title: "", message: "Compartir: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)", preferredStyle: UIAlertControllerStyle.actionSheet)
        let tweetAction = UIAlertAction(title: "En Twitter", style: UIAlertActionStyle.default) { (action) -> Void in
            if(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)) {
                let tweet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                tweet?.setInitialText("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
                tweet?.add(UIImage(named: "cinemas-logo.png"))
                self.present(tweet!, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Twitter", message: "Twitter no está disponible", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        let facebookAction = UIAlertAction(title: "En Facebook", style: UIAlertActionStyle.default) { (action) -> Void in
            if (SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook))
            {
                let post = SLComposeViewController(forServiceType: (SLServiceTypeFacebook))
                post?.setInitialText("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
                post?.add(UIImage(named: "cinemas-logo.png"))
                self.present(post!, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Facebook", message: "Facebook no está disponible", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        let dismissAction = UIAlertAction(title: "Cerrar", style: UIAlertActionStyle.cancel) { (action) -> Void in
            
        }
        actionSheet.addAction(tweetAction)
        actionSheet.addAction(facebookAction)
        actionSheet.addAction(dismissAction)
        present(actionSheet, animated: true, completion: nil)
    }
}
