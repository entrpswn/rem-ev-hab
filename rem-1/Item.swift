//
//  Item.swift
//  rem-1
//
//  Created by Vova Kondriianenko on 08.10.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
