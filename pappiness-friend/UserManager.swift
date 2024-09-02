import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

class UserManager: ObservableObject {
    @Published var user: UserData? = nil
    @Published var loading = false
    @Published var userSignedIn = false
    @Published var signingOut = false
    @Published var profileImageData: Data? = nil // Pour stocker l'image de profil téléchargée

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var isUserSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    // Propriété calculée pour l'URL de la photo de profil
    @Published var profilePhotoURL: URL?

    // Fonction pour obtenir l'URL de téléchargement de la photo de profil
    func fetchProfilePhotoURL(completion: @escaping (URL?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        let uid = currentUser.uid
        let storageRef = storage.reference().child("profileImages/\(uid).jpg")
        
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Erreur lors de l'obtention de l'URL de téléchargement: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(url)
        }
    }

    func uploadProfileImage() {
        guard let imageData = profileImageData else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        let uid = currentUser.uid
        let storageRef = storage.reference().child("profileImages/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("Entering uploadProfileImage")
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading profile image: \(error.localizedDescription)")
                return
            }
            
            // Once uploaded successfully, fetch the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL after upload: \(error.localizedDescription)")
                    return
                }
                if let url = url {
                    print("Profile image uploaded successfully. URL: \(url)")
                    
                    // Update profilePhotoURL
                    DispatchQueue.main.async {
                        self.profilePhotoURL = url
                    }
                }
            }
        }
    }



    func fetchAndSaveUser() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("Utilisateur non connecté")
            DispatchQueue.main.async {
                self.loading = false
                self.userSignedIn = false
            }
            return
        }

        let uid = currentUser.uid
        let userRef = db.collection("youngs").whereField("uid", isEqualTo: uid)

        print("Fetching user data for uid: \(uid)")

        do {
            let snapshot = try await userRef.getDocuments()
            let documents = snapshot.documents
            guard !documents.isEmpty else {
                print("Pas de documents trouvés.")
                DispatchQueue.main.async {
                    self.loading = false
                    self.userSignedIn = false
                }
                return
            }

            let data = documents[0].data()
            DispatchQueue.main.async {
                self.user = UserData(
                    uid: data["uid"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    birthDate: data["birthDate"] as? String ?? "",
                    presentation: data["presentation"] as? String ?? "",
                    interests: data["interests"] as? String ?? "",
                    school: data["school"] as? String ?? "",
                    license: data["license"] as? String ?? "",
                    RIB: data["RIB"] as? String ?? "",
                    longitude: data["long"] as? Double ?? 0.0,
                    latitude: data["lat"] as? Double ?? 0.0,
                    holder: data["holder"] as? String ?? ""
                )
                print("User data fetched and set: \(self.user!)")
                self.loading = false
                self.userSignedIn = true
                self.saveUserLocally()
            }
        } catch {
            print("Erreur de récupération des documents: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.loading = false
                self.userSignedIn = false
            }
        }
    }

    func signOut() {
        DispatchQueue.main.async {
            self.signingOut = true
        }
        
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.userSignedIn = false
                self.signingOut = false
                print("User signed out successfully")
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
            DispatchQueue.main.async {
                self.signingOut = false
            }
        }
    }

    func saveUserLocally() {
        if let user = user {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(user)
                UserDefaults.standard.set(data, forKey: "userData")
                print("User data saved locally")
            } catch {
                print("Erreur de sauvegarde des données de l'utilisateur: \(error.localizedDescription)")
            }
        }
    }

    func loadUserLocally() {
        if let data = UserDefaults.standard.data(forKey: "userData") {
            do {
                let decoder = JSONDecoder()
                let loadedUser = try decoder.decode(UserData.self, from: data)
                DispatchQueue.main.async {
                    self.user = loadedUser
                    self.userSignedIn = true
                    print("User data loaded locally: \(self.user!)")
                }
            } catch {
                print("Erreur de chargement des données de l'utilisateur: \(error.localizedDescription)")
            }
        }
    }
}
