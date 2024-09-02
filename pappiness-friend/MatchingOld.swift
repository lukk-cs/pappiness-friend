//
//  MatchingOld.swift
//  pappiness-friend
//
//  Created by Lucas on 6/27/24.
//

import Foundation

struct MatchingOld: Hashable {
    let uid: String
    let firstName: String
    let lastName: String
    let address: String
    let distance: Double
    let commonAvailability: [String: [Int]] // Les disponibilités communes
    let annonceId: String // ID de l'annonce correspondante
    let freq: String // Fréquence de la visite
    var photoURL: String?

}
