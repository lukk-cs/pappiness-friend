//
//  DocumentsView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/5/24.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct DocumentsView: View {
    var uid: String
    @StateObject private var documentManager = DocumentManager()
    @State private var documentURL: URL?
    @State private var imageData: Data?
    @State private var isActionSheetPresented = false
    @State private var isDocumentPickerPresented = false
    @State private var isImagePickerPresented = false
    @State private var isCameraPresented = false
    @State private var selectedDocumentType: String?

    var body: some View {
        VStack {
            Text("Téléchargez les documents suivants pour vos premières visites !")
                .font(.headline)
                .padding()

            DocumentItemView(title: "Document d'identité", exists: documentManager.documentStatus.idExists, uploadAction: {
                presentOptions(forType: "identity")
            })
            DocumentItemView(title: "Déclaration Insee ou Kbis", exists: documentManager.documentStatus.inseeExists, uploadAction: {
                presentOptions(forType: "insee")
            })
            DocumentItemView(title: "Casier judiciaire", exists: documentManager.documentStatus.crimeExists, uploadAction: {
                presentOptions(forType: "crime")
            })
            DocumentItemView(title: "RIB", exists: documentManager.documentStatus.RIBExists, uploadAction: {
                presentOptions(forType: "rib")
            })

            Spacer()
        }
        .onAppear {
            documentManager.fetchDocumentStatus(forUser: uid)
        }
        .actionSheet(isPresented: $isActionSheetPresented) {
            ActionSheet(
                title: Text("Sélectionnez une option"),
                buttons: [
                    .default(Text("Sélectionner un document")) {
                        isDocumentPickerPresented = true
                    },
                    .default(Text("Sélectionner une photo de la galerie")) {
                        isImagePickerPresented = true
                    },
                    .default(Text("Prendre une photo")) {
                        isCameraPresented = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker(documentURL: $documentURL)
                .onDisappear {
                    if let type = selectedDocumentType, let url = documentURL {
                        documentManager.uploadDocument(forUser: uid, documentURL: url, type: type)
                    }
                }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(imageData: $imageData)
                .onDisappear {
                    if let type = selectedDocumentType, let data = imageData {
                        documentManager.uploadImage(forUser: uid, imageData: data, type: type)
                    }
                }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraPicker(imageData: $imageData)
                .onDisappear {
                    if let type = selectedDocumentType, let data = imageData {
                        documentManager.uploadImage(forUser: uid, imageData: data, type: type)
                    }
                }
        }
    }

    func presentOptions(forType type: String) {
        selectedDocumentType = type
        isActionSheetPresented = true
    }
}
