//
//  MarkFavorite.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct MarkFavorite: Codable {
    
    let media_type: String
    let media_id: Int
    let favorite: Bool
 
}
