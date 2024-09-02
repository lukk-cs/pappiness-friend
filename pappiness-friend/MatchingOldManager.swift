import Foundation
import Firebase
import CoreLocation
import FirebaseStorage

actor FetchedOldsManager {
    var fetchedOlds: [MatchingOld] = []

    func reset() {
        fetchedOlds = []
    }

    func append(_ old: MatchingOld) {
        fetchedOlds.append(old)
    }

    func getFetchedOlds() -> [MatchingOld] {
        return fetchedOlds
    }
}

class MatchingOldManager: ObservableObject {
    @Published var oldsList: [MatchingOld] = []
    @Published var isLoading: Bool = false
    @Published var hasMadeRequest: Bool = false
    let fetchedOldsManager = FetchedOldsManager()

    func checkUserRequestStatus(forUser uid: String) async {
        let db = Firestore.firestore()
        let annoncesJeunesRef = db.collection("annoncesJeunes").whereField("user", isEqualTo: uid)
        
        do {
            let snapshot = try await annoncesJeunesRef.getDocuments()
            await MainActor.run {
                self.hasMadeRequest = !snapshot.documents.isEmpty
            }
        } catch {
            print("Error checking user request status: \(error.localizedDescription)")
        }
    }
    
    func appendIfNotExists(_ old: MatchingOld) async {
        await MainActor.run {
            if !self.oldsList.contains(where: { $0.annonceId == old.annonceId }) {
                self.oldsList.append(old)
            }
        }
    }

    func fetchMatchingOlds(forUser uid: String) async {
        await MainActor.run {
            self.isLoading = true
            self.oldsList = [] // Réinitialiser la liste avant de charger de nouvelles données
        }
        
        print("Fetching matching olds for user with UID: \(uid)")

        let db = Firestore.firestore()
        var youngAvailability: [String: [Int]] = [:]
        var youngLocation = CLLocation(latitude: 0, longitude: 0)

        // Fetch jeunes availability
        let jeunesRef = db.collection("annoncesJeunes").whereField("user", isEqualTo: uid)
        do {
            print("Fetching jeunes availability for user with UID: \(uid)")
            let jeunesSnapshot = try await jeunesRef.getDocuments()
            for doc in jeunesSnapshot.documents {
                youngAvailability = doc.data()["hours"] as? [String: [Int]] ?? [:]
                print("Fetched jeunes availability: \(youngAvailability)")
            }
        } catch {
            print("Error fetching jeunes availability: \(error.localizedDescription)")
        }

        // Fetch young user location
        let youngsRef = db.collection("youngs").whereField("uid", isEqualTo: uid)
        do {
            print("Fetching young user location for user with UID: \(uid)")
            let youngsSnapshot = try await youngsRef.getDocuments()
            for doc in youngsSnapshot.documents {
                let data = doc.data()
                if let lat = data["lat"] as? Double, let lon = data["long"] as? Double {
                    youngLocation = CLLocation(latitude: lat, longitude: lon)
                    print("Fetched young user location: \(youngLocation)")
                }
            }
        } catch {
            print("Error fetching young user location: \(error.localizedDescription)")
        }

        // Créez des copies immuables des variables partagées
        let immutableYoungAvailability = youngAvailability
        let immutableYoungLocation = youngLocation

        // Fetch olds data
        let vieuxRef = db.collection("annoncesVieux")
        do {
            print("Fetching olds data")
            let vieuxSnapshot = try await vieuxRef.getDocuments()
            
            // Utilisation d'un TaskGroup pour gérer les tâches de manière concurrente
            try await withThrowingTaskGroup(of: Void.self) { group in
                for doc in vieuxSnapshot.documents {
                    group.addTask { [immutableYoungAvailability, immutableYoungLocation] in
                        let oldData = doc.data()
                        let hours = oldData["hours"] as? [String: [Int]] ?? [:]
                        var matchingHours: [String: [Int]] = [:]

                        print("Checking availability for old with UID: \(oldData["user"] as? String ?? "Unknown")")

                        for (day, _) in hours {
                            if let youngDayHours = immutableYoungAvailability[day],
                               let oldDayHours = hours[day],
                               oldDayHours[1] == 0, youngDayHours[1] == 0,
                               oldDayHours[0] <= youngDayHours[0] {
                                matchingHours[day] = oldDayHours
                                print("Found matching hours for day \(day): \(matchingHours[day] ?? [])")
                            }
                        }

                        if !matchingHours.isEmpty {
                            let distance = self.calculateDistanceBetweenCoordinates(lat1: immutableYoungLocation.coordinate.latitude,
                                                                                    lon1: immutableYoungLocation.coordinate.longitude,
                                                                                    lat2: oldData["lat"] as? Double ?? 0,
                                                                                    lon2: oldData["long"] as? Double ?? 0)
                            print("Calculated distance: \(distance) km")

                            let oldUid = oldData["user"] as? String ?? ""
                            // Requête pour récupérer le document du vieux en utilisant le champ uid
                            let oldQuerySnapshot = try await db.collection("olds").whereField("uid", isEqualTo: oldUid).getDocuments()
                            for oldDoc in oldQuerySnapshot.documents {
                                let oldDetails = oldDoc.data()
                                let old = MatchingOld(
                                    uid: oldUid,
                                    firstName: oldDetails["firstName"] as? String ?? "",
                                    lastName: oldDetails["lastName"] as? String ?? "",
                                    address: oldDetails["address"] as? String ?? "",
                                    distance: distance,
                                    commonAvailability: matchingHours,
                                    annonceId: doc.documentID,
                                    freq: oldData["freq"] as? String ?? "",
                                    photoURL: nil
                                )

                                
                                // Utiliser une copie de old dans la closure de getUserProfileImage
                                await self.getUserProfileImage(userId: old.uid) { imageUrl in
                                    Task {
                                        var updatedOld = old
                                        updatedOld.photoURL = imageUrl ?? "defaultImageURL" // Assignez une URL de photo par défaut
                                        await self.appendIfNotExists(updatedOld)
                                        print("Added old to fetchedOlds: \(updatedOld)")
                                    }
                                }
                            }
                        } else {
                            print("No matching hours found for old with UID: \(oldData["user"] as? String ?? "Unknown")")
                        }
                    }
                }
                // Attend que toutes les tâches dans le groupe soient terminées
                try await group.waitForAll()
            }

            // Update oldsList on the main actor
            let fetchedOlds = await fetchedOldsManager.getFetchedOlds()
            await MainActor.run {
                self.oldsList = fetchedOlds
                self.isLoading = false
                print("Matching olds fetched successfully.")
                print("Matching olds count: \(self.oldsList.count)")
                for old in self.oldsList {
                    print("Matching old in list: \(old)")
                }
            }

        } catch {
            print("Error fetching olds data: \(error.localizedDescription)")

            // Handle error on the main actor
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func getUserProfileImage(userId: String, completion: @escaping (String?) -> Void) async {
        let storage = Storage.storage()
        let imagePath = "user_images/\(userId)/profile.jpg"
        let imageRef = storage.reference(withPath: imagePath)
        
        imageRef.downloadURL { url, error in
            if let error = error {
                if (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                    print("L'image de profil n'a pas été trouvée dans Firebase Storage.")
                } else {
                    print("Erreur lors de la récupération de l'URL de l'image de profil :", error.localizedDescription)
                }
                completion(nil)
            } else {
                completion(url?.absoluteString)
            }
        }
    }
    
    func handleAcceptOffer(uidYoung: String, old: MatchingOld?) async {
        guard let old = old else { return }

        do {
            try await updateAvailabilityStatus(uidYoung: uidYoung, annonceIdOld: old.annonceId, commonAvailability: old.commonAvailability)
            try await createMatchingDoc(uidYoung: uidYoung, uidOld: old.uid, availability: old.commonAvailability)
            print("Offer accepted successfully.")
        } catch {
            print("Error accepting offer: \(error.localizedDescription)")
        }
    }

    func handleDeclineOffer(annonceId: String, uidYoung: String) async {
        let db = Firestore.firestore()

        do {
            try await markOfferAsDeclined(db: db, annonceId: annonceId, jeuneUid: uidYoung)
            print("Offer declined successfully.")
        } catch {
            print("Error declining offer: \(error.localizedDescription)")
        }
    }

    private func updateAvailabilityStatus(uidYoung: String, annonceIdOld: String, commonAvailability: [String: [Int]]) async throws {
        let db = Firestore.firestore()

        // Mettre à jour les heures dans annoncesJeunes
        let jeunesQuery = db.collection("annoncesJeunes").whereField("user", isEqualTo: uidYoung)
        let jeunesSnapshot = try await jeunesQuery.getDocuments()
        guard let annonceIdYoung = jeunesSnapshot.documents.first?.documentID else { return }

        let jeunesDocRef = db.collection("annoncesJeunes").document(annonceIdYoung)
        var newAvailabilityYoung = [String: [Int]]()
        for (day, hours) in commonAvailability {
            newAvailabilityYoung[day] = [hours[0], 1]
        }
        try await jeunesDocRef.updateData(["hours": newAvailabilityYoung])

        // Mettre à jour les heures dans annoncesVieux
        let vieuxDocRef = db.collection("annoncesVieux").document(annonceIdOld)
        var newAvailabilityOld = [String: [Int]]()
        for (day, hours) in commonAvailability {
            newAvailabilityOld[day] = [hours[0], 1]
        }
        try await vieuxDocRef.updateData(["hours": newAvailabilityOld])

        print("Availability status updated successfully.")
    }

    private func markOfferAsDeclined(db: Firestore, annonceId: String, jeuneUid: String) async throws {
        let annonceRef = db.collection("annoncesVieux").document(annonceId)
        let annonceDoc = try await annonceRef.getDocument()
        
        guard annonceDoc.exists else {
            print("No announcement found with ID \(annonceId).")
            return
        }

        var declined = annonceDoc.data()?["declined"] as? [String] ?? []
        if !declined.contains(jeuneUid) {
            declined.append(jeuneUid)
            try await annonceRef.updateData(["declined": declined])
            print("Offer with ID \(annonceId) marked as declined by young with UID \(jeuneUid).")
        } else {
            print("Offer with ID \(annonceId) was already declined by young with UID \(jeuneUid).")
        }
    }

    private func createMatchingDoc(uidYoung: String, uidOld: String, availability: [String: [Int]]) async throws {
        let db = Firestore.firestore()

        var formattedAvailability = [String: Int]()
        for (day, hours) in availability {
            formattedAvailability[day] = hours[0]
        }

        let _ = try await db.collection("matchings").addDocument(data: [
            "uid_young": uidYoung,
            "uid_old": uidOld,
            "availability": formattedAvailability
        ])

        print("New matching document created successfully.")
    }

    private func calculateDistanceBetweenCoordinates(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)
        return location1.distance(from: location2) / 1000 // in kilometers
    }
}
