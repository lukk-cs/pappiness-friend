//
//  MessageViewModel.swift
//  pappiness-friend
//
//  Created by Lucas on 7/4/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

class MessagesViewModel: ObservableObject {
    @Published var uidYoung: String = ""
    @Published var oldNames: [OldName] = []
    @Published var oldImages: [String?] = []
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func fetchOldNames() {
        guard let user = auth.currentUser else {
            print("Utilisateur non connecté")
            return
        }
        
        self.uidYoung = user.uid
        let matchingsRef = db.collection("matchings")
        let matchingsQuery = matchingsRef.whereField("uid_young", isEqualTo: self.uidYoung)
        
        matchingsQuery.getDocuments { (snapshot, error) in
            if let error = error {
                print("Erreur lors de la récupération des matchings: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            let oldIds = documents.map { $0.data()["uid_old"] as! String }
            self.fetchOldNamesAndImages(for: oldIds)
        }
    }
    
    private func fetchOldNamesAndImages(for oldIds: [String]) {
        let vieuxRef = db.collection("olds")
        var vieuxNames: [OldName] = []
        
        let group = DispatchGroup()
        
        for oldId in oldIds {
            group.enter()
            let vieuxQuery = vieuxRef.whereField("uid", isEqualTo: oldId)
            
            vieuxQuery.getDocuments { (snapshot, error) in
                defer { group.leave() }
                
                if let error = error {
                    print("Erreur lors de la récupération des noms utilisateur: \(error)")
                    return
                }
                
                guard let document = snapshot?.documents.first else { return }
                let data = document.data()
                let name = "\(data["firstName"] as! String) \(data["lastName"] as! String)"
                vieuxNames.append(OldName(uidOld: oldId, nameOld: name))
            }
        }
        
        group.notify(queue: .main) {
            self.oldNames = vieuxNames
            self.fetchOldImages(for: vieuxNames)
        }
    }
    
    private func fetchOldImages(for oldNames: [OldName]) {
        var images: [String?] = Array(repeating: nil, count: oldNames.count)
        
        let group = DispatchGroup()
        
        for (index, oldName) in oldNames.enumerated() {
            group.enter()
            getUserProfileImage(userId: oldName.uidOld) { imageUrl in
                images[index] = imageUrl
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.oldImages = images
        }
    }
    
    private func getUserProfileImage(userId: String, completion: @escaping (String?) -> Void) {
        let imagePath = "user_images/\(userId)/profile.jpg"
        let imageRef = storage.reference().child(imagePath)
        
        imageRef.downloadURL { (url, error) in
            if let error = error {
                print("Erreur lors de la récupération de l'URL de l'image de profil : \(error)")
                completion(nil)
                return
            }
            
            completion(url?.absoluteString)
        }
    }
}

struct OldName: Identifiable {
    var id: String { uidOld }
    var uidOld: String
    var nameOld: String
}
