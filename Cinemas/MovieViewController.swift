//
//  MovieViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit

class MovieViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    @IBOutlet weak var sipnosisLabel: UILabel!
    @IBOutlet weak var actorsLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    
    var movieInfo = [String:String]()
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Película...")
        self.sipnosisLabel.text = movieInfo["sinopsis"] == "" ? "Sinopsis: No disponible" : movieInfo["sinopsis"]
        self.actorsLabel.text = movieInfo["actors"] == "" ? "Actores: No disponible" : movieInfo["actors"]
        self.directorLabel.text = movieInfo["director"] == "" ? "Director: No disponible" : movieInfo["actors"]
    }
    
    override func viewDidAppear(animated: Bool) {
        self.loaderBackgroundView.hidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = movieInfo["title"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func databaseQueue(movieInfo: [String:String]) {
        self.movieInfo = movieInfo
    }
}

