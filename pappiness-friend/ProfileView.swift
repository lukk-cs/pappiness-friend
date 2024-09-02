//
//  ProfileView.swift
//  pappiness-friend
//
//  Created by Lucas on 6/26/24.
//

import SwiftUI
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var isShowingImagePicker = false

    var body: some View {
        VStack {
            if let user = userManager.user {
                Text("Profil de \(user.firstName) \(user.lastName)")
                    .font(.largeTitle)
                    .padding()

                // Affichage de la photo de profil avec AsyncImage
                if let profilePhotoURL = userManager.profilePhotoURL {
                    AsyncImage(url: profilePhotoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }

                // Bouton pour télécharger ou modifier la photo de profil
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Text("Modifier la photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(imageData: $userManager.profileImageData)
                        .onDisappear {
                            userManager.uploadProfileImage()
                        }
                }

            } else {
                Text("Aucun utilisateur connecté")
                    .font(.largeTitle)
                    .padding()
            }
        }
        .onAppear {
            if let user = userManager.user {
                userManager.fetchProfilePhotoURL { url in
                    DispatchQueue.main.async {
                        self.userManager.profilePhotoURL = url // Mettre à jour profilePhotoURL
                    }
                }
            }
        }
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserManager())
            .environmentObject(MeetingManager())
    }
}
