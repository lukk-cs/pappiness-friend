//
//  MatchFunc.swift
//  pappiness-friend
//
//  Created by Lucas on 6/25/24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

func calculateDistance(uidYoung: String, uidOld: String, completion: @escaping (Double?) -> Void) {
    let db = Firestore.firestore()
    let youngs = db.collection("youngs")
    let olds = db.collection("olds")
    
    let youngQuery = youngs.whereField("uid", isEqualTo: uidYoung)
    let oldQuery = olds.whereField("uid", isEqualTo: uidOld)
    
    youngQuery.getDocuments { (youngSnapshot, error) in
        if let error = error {
            print("Error getting young document: \(error)")
            completion(nil)
            return
        }
        
        oldQuery.getDocuments { (oldSnapshot, error) in
            if let error = error {
                print("Error getting old document: \(error)")
                completion(nil)
                return
            }
            
            guard let youngData = youngSnapshot?.documents.first?.data(),
                  let oldData = oldSnapshot?.documents.first?.data(),
                  let latYoung = youngData["lat"] as? Double,
                  let lonYoung = youngData["long"] as? Double,
                  let latOld = oldData["lat"] as? Double,
                  let lonOld = oldData["long"] as? Double else {
                print("No user document found for these UIDs.")
                completion(nil)
                return
            }
            
            let locationYoung = CLLocation(latitude: latYoung, longitude: lonYoung)
            let locationOld = CLLocation(latitude: latOld, longitude: lonOld)
            
            let distanceInMeters = locationYoung.distance(from: locationOld)
            let distanceInKilometers = distanceInMeters / 1000.0
            
            completion(distanceInKilometers)
        }
    }
}


func filterOldsByAvailability(youngAvailability: [String: [Int]], oldsList: [[String: Any]]) -> [[String: Any]] {
    var matchingOlds: [[String: Any]] = []
    
    for old in oldsList {
        guard let oldAvailability = old["hours"] as? [String: [Int]] else { continue }
        var commonAvailability: [String: [Int]] = [:]
        
        for (day, hours) in oldAvailability {
            if let youngHours = youngAvailability[day], hours[1] == 0, youngHours[1] == 0, hours[0] <= youngHours[0] {
                commonAvailability[day] = hours
            }
        }
        
        if !commonAvailability.isEmpty {
            var matchingOld = old
            matchingOld["commonAvailability"] = commonAvailability
            matchingOlds.append(matchingOld)
        }
    }
    
    return matchingOlds
}

func filterOldsByDistance(youngLocation: CLLocation, oldsList: [[String: Any]], maxDistance: Double, completion: @escaping ([[String: Any]]) -> Void) {
    var nearbyOlds: [[String: Any]] = []
    let db = Firestore.firestore()
    let olds = db.collection("olds")
    
    let group = DispatchGroup()
    
    for old in oldsList {
        group.enter()
        
        guard let oldUid = old["uid"] as? String else {
            group.leave()
            continue
        }
        
        let oldQuery = olds.whereField("uid", isEqualTo: oldUid)
        oldQuery.getDocuments { (snapshot, error) in
            defer { group.leave() }
            
            if let error = error {
                print("Error getting old document: \(error)")
                return
            }
            
            guard let oldData = snapshot?.documents.first?.data(),
                  let latOld = oldData["lat"] as? Double,
                  let lonOld = oldData["long"] as? Double else {
                print("No old document found for UID: \(oldUid)")
                return
            }
            
            let locationOld = CLLocation(latitude: latOld, longitude: lonOld)
            let distance = youngLocation.distance(from: locationOld)
            
            if distance <= maxDistance {
                var nearbyOld = old
                nearbyOld["distance"] = distance / 1000.0 // Convert to kilometers
                nearbyOlds.append(nearbyOld)
            }
        }
    }
    
    group.notify(queue: .main) {
        completion(nearbyOlds)
    }
}

func proposeMatchingOlds(youngAvailability: [String: [Int]], youngLocation: CLLocation, oldsList: [[String: Any]], maxDistance: Double, completion: @escaping ([[String: Any]]) -> Void) {
    let matchingOldsByAvailability = filterOldsByAvailability(youngAvailability: youngAvailability, oldsList: oldsList)
    filterOldsByDistance(youngLocation: youngLocation, oldsList: matchingOldsByAvailability, maxDistance: maxDistance) { matchingOldsByDistance in
        completion(matchingOldsByDistance)
    }
}

func updateAvailabilityStatus(uidYoung: String, annonceIdOld: String, commonAvailability: [String: [Int]], completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()
    
    let jeunesQuery = db.collection("annoncesJeunes").whereField("user", isEqualTo: uidYoung)
    jeunesQuery.getDocuments { (snapshot, error) in
        if let error = error {
            print("Error getting jeunes document: \(error)")
            completion(false)
            return
        }
        
        guard let jeuneDoc = snapshot?.documents.first else {
            print("No jeune document found for UID: \(uidYoung)")
            completion(false)
            return
        }
        
        let annonceIdYoung = jeuneDoc.documentID
        let jeunesDocRef = db.collection("annoncesJeunes").document(annonceIdYoung)
        var newAvailabilityYoung: [String: [Int]] = [:]
        
        for (day, hours) in commonAvailability {
            newAvailabilityYoung[day] = [hours[0], 1]
        }
        
        jeunesDocRef.updateData(["hours": newAvailabilityYoung]) { error in
            if let error = error {
                print("Error updating jeunes document: \(error)")
                completion(false)
                return
            }
            
            let vieuxDocRef = db.collection("annoncesVieux").document(annonceIdOld)
            var newAvailabilityOld: [String: [Int]] = [:]
            
            for (day, hours) in commonAvailability {
                newAvailabilityOld[day] = [hours[0], 1]
            }
            
            vieuxDocRef.updateData(["hours": newAvailabilityOld]) { error in
                if let error = error {
                    print("Error updating vieux document: \(error)")
                    completion(false)
                } else {
                    print("Hours successfully updated in annoncesJeunes and annoncesVieux")
                    completion(true)
                }
            }
        }
    }
}


func markOfferAsDeclined(db: Firestore, annonceId: String, jeuneUid: String, completion: @escaping (Bool) -> Void) {
    let annonceRef = db.collection("annoncesVieux").document(annonceId)
    
    annonceRef.getDocument { (document, error) in
        if let document = document, document.exists {
            let data = document.data() //var avant
            var declined = data?["declined"] as? [String] ?? []
            
            if !declined.contains(jeuneUid) {
                declined.append(jeuneUid)
                annonceRef.updateData(["declined": declined]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                        completion(false)
                    } else {
                        print("Offer marked as declined by young UID: \(jeuneUid)")
                        completion(true)
                    }
                }
            } else {
                print("Offer already declined by young UID: \(jeuneUid)")
                completion(true)
            }
        } else {
            print("No document found with ID: \(annonceId)")
            completion(false)
        }
    }
}


func createMatchingDoc(uidYoung: String, uidOld: String, availability: [String: [Int]], completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()
    var formattedAvailability: [String: Int] = [:]
    
    for (day, hours) in availability {
        formattedAvailability[day] = hours[0]
    }
    
    let matchingsRef = db.collection("matchings")
    matchingsRef.addDocument(data: [
        "uid_young": uidYoung,
        "uid_old": uidOld,
        "availability": formattedAvailability
    ]) { error in
        if let error = error {
            print("Error creating matching document: \(error)")
            completion(false)
        } else {
            print("New matching document created")
            completion(true)
        }
    }
}

func filterDaysObj(daysObj: [String: [Int]]) -> [String: [Int]] {
    var filteredDays: [String: [Int]] = [:]
    
    for (day, hours) in daysObj {
        if hours[1] == 0 {
            filteredDays[day] = hours
        }
    }
    
    return filteredDays
}
