//
//  AuthFunctions.swift
//  pappiness-friend
//
//  Created by Lucas on 6/24/24.
//

import Firebase

class AuthFunctions {
    static func signUp(firstName: String, lastName: String, phone: String, email: String, address: String, lat: Double, long: Double, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "No user", code: -1, userInfo: nil)))
                return
            }
            let db = Firestore.firestore()
            db.collection("youngs").document(user.uid).setData([
                "uid": user.uid,
                "firstName": firstName,
                "lastName": lastName,
                "phone": phone,
                "email": email,
                "address": address,
                "lat": lat,
                "long": long
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    static func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "No user", code: -1, userInfo: nil)))
                return
            }
            let db = Firestore.firestore()
            db.collection("youngs").whereField("uid", isEqualTo: user.uid).getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if querySnapshot?.isEmpty == false {
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "User document not found", code: -1, userInfo: nil)))
                }
            }
        }
    }
}

