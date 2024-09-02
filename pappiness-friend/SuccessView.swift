//
//  SuccessView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/8/24.
//

import SwiftUI

struct SuccessView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var name: String
    var uid: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("party-popper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text("Vos heures ont été enregistrées avec succès !")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()

                Text("Pour que nous puissions trouver la solution la plus adaptée, nous avons besoin que vous complétiez votre profil")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()

                VStack(spacing: 10) {
                    NavigationLink(destination: AddInfosView(name: name, uid: uid)) {
                        Text("Compléter mon profil")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Revenir à l'accueil")
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct SuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessView(name: "John Doe", uid: "12345")
    }
}
