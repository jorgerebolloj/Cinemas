//
//  GalleryViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit
import CoreData
import FMDB
import TNImageSliderViewController

class GalleryViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    
    var queue: FMDatabaseQueue?
    var cityId: String!
    var movieInfo = [String:String]()
    let activityIndicator = ActivityIndicator()
    var imageSliderViewController:TNImageSliderViewController!
    var imagesNames = [String]()
    var images = [NSManagedObject]()
    var imagesArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Galería"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Galería...")
        
        print(self.imagesNames)
        
        for imageData in images {
            let image = imageData.valueForKey("imageMovie") as! NSData
            imagesArray.append(UIImage(data: image)!)
        }
        
        if images.isEmpty == false {
            imageSliderViewController.images = imagesArray
            print(imageSliderViewController.images.count)
            
            var options = TNImageSliderViewOptions()
            options.pageControlHidden = false
            options.scrollDirection = .Horizontal
            options.pageControlCurrentIndicatorTintColor = UIColor.yellowColor()
            options.autoSlideIntervalInSeconds = 2
            options.shouldStartFromBeginning = true
            options.imageContentMode = .ScaleAspectFit
            
            imageSliderViewController.options = options
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Galería"
    }
    
    override func viewDidAppear(animated: Bool) {
        self.loaderBackgroundView.hidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "ImageSliderSegue" ) {
            imageSliderViewController = segue.destinationViewController as! TNImageSliderViewController
        }
    }
    
    func databaseQueue(cityId: String, movieInfo: [String:String]) {
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
            
            do {
                let rs = try database.executeQuery("select * from Multimedia where IdPelicula = \(self.movieInfo["movie"]!)  and Tipo = 'Imagen'", values: nil)
                while rs.next() {
                    let imageName = rs.stringForColumn("Archivo")
                    self.imagesNames.append(imageName)
                    self.requestImage(imageName)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            database.close()
        })
    }
    
    func requestImage(imageName: String) {
        let url = NSURL(string: Constants.apiUrlGallery + imageName)
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
                        self.saveImage(nsdata)
                    }
                }
            })
            task.resume()
        })
    }
    
    func saveImage(imageData: NSData) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity = NSEntityDescription.entityForName("MovieImages", inManagedObjectContext: managedContext)
        let imageMovie = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        imageMovie.setValue(imageData, forKey: "imageMovie")
        
        do {
            try managedContext.save()
            images.append(imageMovie)
        } catch let error as NSError {
            print("No hemos podido persistir debido al error \(error), \(error.userInfo)")
        }
    }
}