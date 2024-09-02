//
//  MessageView.swift
//  pappiness-friend
//
//  Created by Lucas on 6/26/24.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Messages")
                    .font(.largeTitle)
                    .padding()
                
                if viewModel.oldNames.isEmpty {
                    Text("Planifie un rendez-vous pour pouvoir envoyer des messages !")
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        ForEach(viewModel.oldNames) { oldName in
                            HStack {
                                if let imageUrl = viewModel.oldImages.first(where: { $0?.contains(oldName.uidOld) == true }) {
                                    AsyncImage(url: URL(string: imageUrl ?? "")) { image in
                                        image.resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                }
                                
                                NavigationLink(destination: ChatPage(uid_young: viewModel.uidYoung, uid_old: oldName.uidOld, name_old: oldName.nameOld)) {
                                    HStack {
                                        Text(oldName.nameOld)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchOldNames()
            }
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
