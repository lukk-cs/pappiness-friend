//
//  AddInfosView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/8/24.
//

import SwiftUI

struct AddInfosView: View {
    var name: String
    var uid: String

    var body: some View {
        Text("Compléter le profil pour \(name)")
        // Ajoutez le contenu et la logique de la vue ici
    }
}

struct AddInfosView_Previews: PreviewProvider {
    static var previews: some View {
        AddInfosView(name: "John Doe", uid: "12345")
    }
}
