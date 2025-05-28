//
//  Item.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
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
