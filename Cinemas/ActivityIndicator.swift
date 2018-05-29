//
//  ActivityIndicator.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 02/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit

class ActivityIndicator: UIView {
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    func activityIndicator(title: String) {
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 46))
        strLabel.text = title
        strLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        strLabel.textColor = UIColor(red:0.99, green:0.72, blue:0.15, alpha:1.0)
        
        effectView.frame = CGRect(x: superview!.frame.midX - strLabel.frame.width/2, y: superview!.frame.midY - strLabel.frame.height/2 , width: 220, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.color = UIColor(red:0.99, green:0.72, blue:0.15, alpha:1.0)
        activityIndicator.startAnimating()
        
        effectView.addSubview(activityIndicator)
        effectView.addSubview(strLabel)
        superview!.addSubview(effectView)
    }
}
