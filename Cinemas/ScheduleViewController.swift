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
    
    override func viewDidAppear(animated: Bool) {
        self.tabBarController?.navigationItem.title = "Horarios"
        self.loaderBackgroundView.hidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func databaseQueue(cityId: String, movieInfo: [String:String]) {
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.todayString = dateFormatter.stringFromDate(todaysDate)
        
        self.cityId = cityId
        self.movieInfo = movieInfo
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
            
            let queryString = "select Horario, Sala from Cartelera where IdPelicula = \(self.movieInfo["movie"]!) and Fecha = '\(self.todayString!)'  order by Sala"
            print(queryString)
            
            do {
                let rs = try database.executeQuery(queryString, values: nil)
                while rs.next() {
                    var timesDictionary = [String: String]()
                    let time = rs.stringForColumn("Horario")
                    let room = rs.stringForColumn("Sala")
                    timesDictionary["time"] = time
                    timesDictionary["room"] = room
                    self.times.append(timesDictionary)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            database.close()
        })
    }
}

extension ScheduleViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.times.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleCell", forIndexPath: indexPath)
        //let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleCell", forIndexPath: indexPath) as! ScheduleTableViewCell
        let timeInfo = self.times[indexPath.row]
        cell.textLabel?.text = "Horario: \(timeInfo["time"]!) hrs. Sala: \(timeInfo["room"]!)"
        cell.textLabel?.textColor = UIColor(red: 253/255.0, green: 184/255.0, blue: 39/255.0, alpha: 1.0)
        cell.textLabel?.font = UIFont(name:"System-Bold", size: 17.0)
        /*cell.scheduleLabel?.text = "Horario: \(timeInfo["time"]!)"
        cell.roomLabel?.text = "Sala: \(timeInfo["room"]!)"*/
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let timeInfo = self.times[indexPath.row]
        print("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
        let actionSheet = UIAlertController(title: "", message: "Compartir: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let tweetAction = UIAlertAction(title: "En Twitter", style: UIAlertActionStyle.Default) { (action) -> Void in
            if(SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)) {
                let tweet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                tweet.setInitialText("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
                tweet.addImage(UIImage(named: "cinemas-logo.png"))
                self.presentViewController(tweet, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Twitter", message: "Twitter no está disponible", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        let facebookAction = UIAlertAction(title: "En Facebook", style: UIAlertActionStyle.Default) { (action) -> Void in
            if (SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook))
            {
                let post = SLComposeViewController(forServiceType: (SLServiceTypeFacebook))
                post.setInitialText("Quiero compartirles la película: '\(self.movieInfo["title"]!)', Sala: \(timeInfo["room"]!) a las \(timeInfo["time"]!)")
                post.addImage(UIImage(named: "cinemas-logo.png"))
                self.presentViewController(post, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Facebook", message: "Facebook no está disponible", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        let dismissAction = UIAlertAction(title: "Cerrar", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            
        }
        actionSheet.addAction(tweetAction)
        actionSheet.addAction(facebookAction)
        actionSheet.addAction(dismissAction)
        presentViewController(actionSheet, animated: true, completion: nil)
    }
}
