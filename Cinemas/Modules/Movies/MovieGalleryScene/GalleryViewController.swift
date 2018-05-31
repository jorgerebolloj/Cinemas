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
import Alamofire
//import TNImageSliderViewController
// Deleted TNImageSliderViewController as class of GalleryViewController.swift

class GalleryViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    
    var queue: FMDatabaseQueue?
    var cityId: String!
    var movieInfo = [String:String]()
//    let activityIndicator = ActivityIndicator()
//    var imageSliderViewController:TNImageSliderViewController!
    var imagesNames = [String]()
    var images = [NSManagedObject]()
    var imagesArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Galería"
//        self.view.addSubview(activityIndicator)
//        activityIndicator.activityIndicator("Cargando Galería...")
        
        print(self.imagesNames)
        
        for imageData in images {
            let image = imageData.value(forKey: "imageMovie") as! Data
            imagesArray.append(UIImage(data: image)!)
        }
        
        if images.isEmpty == false {
//            TrailerViewController.images = imagesArray
//            print(imageSliderViewController.images.count)
            
//            var options = TNImageSliderViewOptions()
//            options.pageControlHidden = false
//            options.scrollDirection = .horizontal
//            options.pageControlCurrentIndicatorTintColor = UIColor.yellow
//            options.autoSlideIntervalInSeconds = 2
//            options.shouldStartFromBeginning = true
//            options.imageContentMode = .scaleAspectFit
//            
//            imageSliderViewController.options = options
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Galería"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loaderBackgroundView.isHidden = true
//        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "ImageSliderSegue" ) {
//            imageSliderViewController = segue.destination as! TNImageSliderViewController
        }
    }
    
    func databaseQueue(_ cityId: String, movieInfo: [String:String]) {
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
            
            do {
                let rs = try database.executeQuery("select * from Multimedia where IdPelicula = \(self.movieInfo["movie"]!)  and Tipo = 'Imagen'", values: nil)
                while rs.next() {
                    let imageName = rs.string(forColumn: "Archivo")
                    self.imagesNames.append(imageName!)
                    self.requestImage(imageName!)
                }
            } catch let error as NSError {
                print("failed: \(error.localizedDescription)")
            }
            
            database.close()
        })
    }
    
    func requestImage(_ imageName: String) {
        Alamofire.request(Constants.apiUrlGallery + imageName).responseData { response in
            if let data = response.result.value {
                self.saveImage(data)
            }
        }
        
//        let url = URL(string: Constants.apiUrlGallery + imageName)
//        let session = URLSession.shared
//        
//        let qualityOfServiceClass = DispatchQoS.QoSClass.background
//        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
//        backgroundQueue.async(execute: {
//            let task = session.dataTask(with: url!, completionHandler: {data, response, error -> Void in
//                if(error != nil) {
//                    print(error!.localizedDescription)
//                } else {
//                    let nsdata:Data = NSData(data: data!) as Data
//                    do {
//                        self.saveImage(nsdata)
//                    }
//                }
//            })
//            task.resume()
//        })
    }
    
    func saveImage(_ imageData: Data) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity = NSEntityDescription.entity(forEntityName: "MovieImages", in: managedContext)
        let imageMovie = NSManagedObject(entity: entity!, insertInto: managedContext)
        imageMovie.setValue(imageData, forKey: "imageMovie")
        
        do {
            try managedContext.save()
            images.append(imageMovie)
        } catch let error as NSError {
            print("No hemos podido persistir debido al error \(error), \(error.userInfo)")
        }
    }
}
