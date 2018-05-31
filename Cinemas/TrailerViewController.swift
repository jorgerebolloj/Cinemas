//
//  TrailerViewController.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit

class TrailerViewController: UIViewController {
    @IBOutlet weak var loaderBackgroundView: UIView!
    
    let activityIndicator = ActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trailer"
        self.view.addSubview(activityIndicator)
        activityIndicator.activityIndicator("Cargando Trailer...")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loaderBackgroundView.isHidden = true
        self.activityIndicator.effectView.removeFromSuperview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Trailer"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
