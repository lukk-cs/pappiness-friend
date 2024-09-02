import Combine
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class DocumentManager: ObservableObject {
    @Published var documentStatus = DocumentStatus()
    @Published var isLoading = false

    private var storage = Storage.storage()

    // Fetch document status for a user
    func fetchDocumentStatus(forUser uid: String) {
        isLoading = true
        checkAllDocuments(uid: uid) { status in
            DispatchQueue.main.async {
                self.documentStatus = status
                self.isLoading = false
            }
        }
    }

    // Upload a document for a user
    func uploadDocument(forUser uid: String, documentURL: URL, type: String) {
        isLoading = true
        let documentPath = "user_\(type)/\(uid)/\(type).pdf"
        let documentRef = storage.reference().child(documentPath)

        documentRef.putFile(from: documentURL, metadata: nil) { metadata, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error uploading document: \(error)")
                } else {
                    print("Document successfully uploaded.")
                    self.fetchDocumentStatus(forUser: uid)
                }
            }
        }
    }

    // Upload an image for a user
    func uploadImage(forUser uid: String, imageData: Data, type: String) {
        isLoading = true
        let documentPath = "user_\(type)/\(uid)/\(type).jpg"
        let documentRef = storage.reference().child(documentPath)

        documentRef.putData(imageData, metadata: nil) { metadata, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error uploading image: \(error)")
                } else {
                    print("Image successfully uploaded.")
                    self.fetchDocumentStatus(forUser: uid)
                }
            }
        }
    }

    // Helper functions
    private func checkDocumentExistence(uid: String, documentBasePath: String, completion: @escaping (Bool) -> Void) {
        let storage = Storage.storage()
        let pdfRef = storage.reference(withPath: "\(documentBasePath).pdf")
        let jpgRef = storage.reference(withPath: "\(documentBasePath).jpg")

        pdfRef.downloadURL { url, error in
            if let _ = url {
                completion(true)
            } else {
                print("PDF document \(documentBasePath).pdf does not exist.", error ?? "")

                jpgRef.downloadURL { url, error in
                    if let _ = url {
                        completion(true)
                    } else {
                        print("JPG document \(documentBasePath).jpg does not exist.", error ?? "")
                        completion(false)
                    }
                }
            }
        }
    }

    private func checkRIBExistence(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let query = db.collection("youngs").whereField("uid", isEqualTo: uid)

        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(false)
            } else if let snapshot = snapshot, !snapshot.isEmpty {
                let userDoc = snapshot.documents.first?.data()
                let ribExists = userDoc?["RIB"] != nil
                print("RIB: \(ribExists)")
                completion(ribExists)
            } else {
                completion(false)
            }
        }
    }

    private func checkAllDocuments(uid: String, completion: @escaping (DocumentStatus) -> Void) {
        let group = DispatchGroup()
        var documentStatus = DocumentStatus()

        group.enter()
        checkDocumentExistence(uid: uid, documentBasePath: "user_identity/\(uid)/identity") { exists in
            documentStatus.idExists = exists
            group.leave()
        }

        group.enter()
        checkDocumentExistence(uid: uid, documentBasePath: "user_insee/\(uid)/insee") { exists in
            documentStatus.inseeExists = exists
            group.leave()
        }

        group.enter()
        checkDocumentExistence(uid: uid, documentBasePath: "user_crime/\(uid)/crime") { exists in
            documentStatus.crimeExists = exists
            group.leave()
        }

        group.enter()
        checkRIBExistence(uid: uid) { exists in
            documentStatus.RIBExists = exists
            group.leave()
        }

        group.notify(queue: .main) {
            completion(documentStatus)
        }
    }
}
