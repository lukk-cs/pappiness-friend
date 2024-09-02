//
//  DocumentItemView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/5/24.
//

import SwiftUI

struct DocumentItemView: View {
    var title: String
    var exists: Bool
    var uploadAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: exists ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundColor(exists ? .green : .red)
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: uploadAction) {
                    Text(exists ? "Modifier" : "Ajouter")
                        .foregroundColor(.blue)
                }
            }
            Divider()
        }
        .padding()
    }
}
