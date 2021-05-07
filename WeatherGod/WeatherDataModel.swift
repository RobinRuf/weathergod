//
//  WeatherDataModel.swift
//  WeatherGod
//
//  Created by Robin Ruf on 18.12.20.
//

import UIKit
import Foundation
import SDWebImage // Klassen, Methoden um Bilder aus dem Web zu laden

class WeatherDataModel {
    
    var temp: Int = 0
    var description: String = ""
    var city: String = ""
    var country: String = ""
    var iconName: String = ""
    
    // Methode zum Bild laden
    func loadImagefromURL(imageURL: String, imageView: UIImageView) { // imageURL = URL des Bildes, imageView = ImageView-Object, wo das Bild dargestellt werden soll
        
        guard let url = URL(string: imageURL) else { return }
        imageView.sd_setImage(with: url) { (_, _, _, _) in }
        
    }
    
    
}
