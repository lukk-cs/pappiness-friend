import Foundation
import Firebase
import FirebaseFirestoreSwift
import CoreLocation
import FirebaseStorage

class MeetingManager: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var loading = true
    private let db = Firestore.firestore()

    func fetchMeetings(userData: UserData) {
        let uid = userData.uid
        let meetingsRef = db.collection("matchings").whereField("uid_young", isEqualTo: uid)

        meetingsRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Erreur de récupération des meetings: \(error.localizedDescription)")
                self?.loading = false
                return
            }

            guard let documents = snapshot?.documents else {
                print("Pas de documents trouvés.")
                self?.loading = false
                return
            }

            var fetchedMeetings: [Meeting] = []
            let group = DispatchGroup()

            for document in documents {
                group.enter()
                let data = document.data()
                let uidOld = data["uid_old"] as? String ?? ""
                let availability = data["availability"] as? [String: Int] ?? [:]

                self?.fetchOldData(uidOld: uidOld) { oldData in
                    guard let oldData = oldData else {
                        group.leave()
                        return
                    }

                    self?.fetchAnnonceData(uidOld: uidOld) { annonceData in
                        guard let latYoung = userData.latitude as? Double,
                              let lonYoung = userData.longitude as? Double,
                              let latOld = oldData["lat"] as? Double,
                              let lonOld = oldData["long"] as? Double else {
                            group.leave()
                            return
                        }

                        let distanceInKilometers = self?.calculateDistanceBetweenCoordinates(lat1: latYoung, lon1: lonYoung, lat2: latOld, lon2: lonOld) ?? 0.0

                        var meeting = Meeting(
                            id: document.documentID,
                            uid_old: uidOld,
                            availability: availability,
                            oldName: "\(oldData["firstName"] ?? "") \(oldData["lastName"] ?? "")",
                            address: oldData["address"] as? String ?? "",
                            distance: distanceInKilometers,
                            freq: annonceData?["freq"] as? String ?? "",
                            begin: annonceData?["begin"] as? String ?? "",
                            photoURL: nil
                        )

                        self?.getUserProfileImage(userId: uidOld) { imageUrl in
                            meeting.photoURL = imageUrl
                            fetchedMeetings.append(meeting)
                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self?.meetings = self?.filterObsoleteDaysNextVisits(fetchedMeetings) ?? []
                self?.saveMeetingsLocally()
                self?.loading = false
            }
        }
    }

    func getUserProfileImage(userId: String, completion: @escaping (String?) -> Void) {
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

    private func fetchOldData(uidOld: String, completion: @escaping ([String: Any]?) -> Void) {
        let oldsRef = db.collection("olds").whereField("uid", isEqualTo: uidOld)

        oldsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Erreur de récupération des olds: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let document = snapshot?.documents.first else {
                print("Pas de documents trouvés pour old.")
                completion(nil)
                return
            }

            completion(document.data())
        }
    }

    private func fetchAnnonceData(uidOld: String, completion: @escaping ([String: Any]?) -> Void) {
        let annoncesVieuxRef = db.collection("annoncesVieux").whereField("user", isEqualTo: uidOld)

        annoncesVieuxRef.getDocuments { snapshot, error in
            if let error = error {
                print("Erreur de récupération des annoncesVieux: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let document = snapshot?.documents.first else {
                print("Pas de documents trouvés pour annonce.")
                completion(nil)
                return
            }

            completion(document.data())
        }
    }

    private func filterObsoleteDaysNextVisits(_ fetchedMeetings: [Meeting]) -> [Meeting] {
        var meetings = fetchedMeetings
        let currentDate = Date()
        let calendar = Calendar.current
        let currentDay = (calendar.component(.weekday, from: currentDate) + 5) % 7

        let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

        for i in 0..<meetings.count {
            if meetings[i].freq == "ponctuelle" {
                guard let beginDate = DateFormatter().date(from: meetings[i].begin) else { continue }
                _ = (calendar.component(.weekday, from: beginDate) + 5) % 7

                var daysToRemove: [String] = []

                let millisecondsInOneDay: Double = 1000 * 60 * 60 * 24
                let differenceInMilliseconds: Double = currentDate.timeIntervalSince(beginDate) * 1000
                let differenceInDays = differenceInMilliseconds / millisecondsInOneDay

                for day in meetings[i].availability.keys {
                    let dayName = day.components(separatedBy: " ").first ?? ""
                    let dayIndex = daysOfWeek.firstIndex(of: dayName) ?? -1
                    if dayIndex == -1 { continue }

                    if differenceInDays > 7 || (beginDate <= currentDate && dayIndex < currentDay) {
                        daysToRemove.append(day)
                    }
                }

                for dayToRemove in daysToRemove {
                    meetings[i].availability.removeValue(forKey: dayToRemove)
                }

                if meetings[i].availability.isEmpty {
                    let matchingsRef = db.collection("matchings")
                    let matchingDocRef = matchingsRef.document(meetings[i].id)
                    matchingDocRef.delete { error in
                        if let error = error {
                            print("Erreur de suppression du meeting: \(error.localizedDescription)")
                        } else {
                            print("Meeting deleted: \(meetings[i])")
                        }
                    }
                } else {
                    let matchingsRef = db.collection("matchings")
                    let matchingDocRef = matchingsRef.document(meetings[i].id)
                    matchingDocRef.updateData(["availability": meetings[i].availability]) { error in
                        if let error = error {
                            print("Erreur de mise à jour du meeting: \(error.localizedDescription)")
                        } else {
                            print("Meeting updated: \(meetings[i])")
                        }
                    }
                }
            }
        }

        return meetings.filter { !$0.availability.isEmpty }
    }

    func calculateDistanceBetweenCoordinates(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)

        let distanceInMeters = location1.distance(from: location2)
        let distanceInKilometers = distanceInMeters / 1000

        return distanceInKilometers
    }

    func saveMeetingsLocally() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(meetings)
            UserDefaults.standard.set(data, forKey: "meetingsData")
            print("Meetings saved locally")
        } catch {
            print("Erreur de sauvegarde des meetings: \(error.localizedDescription)")
        }
    }

    func loadMeetingsLocally() {
        if let data = UserDefaults.standard.data(forKey: "meetingsData") {
            do {
                let decoder = JSONDecoder()
                self.meetings = try decoder.decode([Meeting].self, from: data)
                print("Meetings loaded locally: \(self.meetings)")
            } catch {
                print("Erreur de chargement des meetings: \(error.localizedDescription)")
            }
        }
    }
}
