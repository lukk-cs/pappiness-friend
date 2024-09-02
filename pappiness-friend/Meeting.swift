//
//  Meeting.swift
//  pappiness-friend
//
//  Created by Lucas on 6/26/24.
//

import Foundation

struct Meeting: Codable, Identifiable, Hashable {
    var id: String
    var uid_old: String
    var availability: [String: Int]
    var oldName: String
    var address: String
    var distance: Double
    var freq: String
    var begin: String
    var photoURL: String?
}
