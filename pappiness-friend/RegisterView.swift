//
//  RegisterView.swift
//  pappiness-friend
//
//  Created by Lucas on 6/24/24.
//


import SwiftUI
import GooglePlaces

struct RegisterView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var password: String = ""
    @State private var gender: String = ""
    @State private var loading: Bool = false
    @State private var showAutocomplete: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Créer un compte")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()

                VStack(alignment: .leading, spacing: 15) {
                    
                    Picker("Genre", selection: $gender) {
                        Text("Femme").tag("female")
                        Text("Homme").tag("male")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Prénom", text: $firstName)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    TextField("Nom", text: $lastName)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    TextField("Adresse", text: $address)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onTapGesture {
                            self.dismissKeyboard()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.showAutocomplete = true
                            }
                        }

                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)


                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 20) {
                    if loading {
                        ProgressView()
                    } else {
                        Button(action: {
                            signUp()
                        }) {
                            Text("S'inscrire")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.customBlue)
                                .cornerRadius(8)
                        }
                    }

                    HStack {
                        Text("Déjà inscrit ?")
                        NavigationLink(destination: LoginView()) {
                            Text("Se connecter")
                                .foregroundColor(Color.customBlue)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .fullScreenCover(isPresented: $showAutocomplete) {
                GMSAutocompleteViewControllerWrapper(selectedAddress: $address, latitude: $latitude, longitude: $longitude)
                    .onDisappear {
                        self.dismissKeyboard()
                    }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func signUp() {
        loading = true
        errorMessage = nil
        successMessage = nil

        AuthFunctions.signUp(firstName: firstName, lastName: lastName, phone: phone, email: email, address: address, lat: latitude, long: longitude, password: password) { result in
            loading = false
            switch result {
            case .success:
                successMessage = "Compte créé avec succès !"
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}

