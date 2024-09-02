//
//  Models.swift
//  pappiness-friend
//
//  Created by Lucas on 7/4/24.
//

import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var senderUid: String
    var content: String
    var timestamp: Double
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}


struct Conversation: Codable {
    var participants: [String]
}
