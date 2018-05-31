//
//  ScheduleTableViewCell.swift
//  Cinemas
//
//  Created by Jorge Rebollo Jimenez on 06/06/17.
//  Copyright © 2017 personal. All rights reserved.
//

import UIKit

class ScheduleTableViewCell: UITableViewCell {
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    
    /*var schedule: AnyObject! {
        didSet {
            let stringTime = String(schedule.valueForKey("time")!)
            let stringRoom = String(schedule.valueForKey("room")!)
            scheduleLabel.text = stringTime == "" ? "Horario: No disponible" : "Horario: \(stringTime)"
            roomLabel.text = stringTime == "" ? "Sala: No disponible" : "Sala: \(stringRoom)"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }*/
}