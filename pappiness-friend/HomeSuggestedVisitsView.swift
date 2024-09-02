//
//  HomeSuggestedVisitsView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/29/24.
//

import SwiftUI

struct HomeSuggestedVisitsView: View {
    var oldsList: [MatchingOld]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Visites suggérées:")
                .font(.headline)
                .padding(.top)
                .padding(.leading)

            if oldsList.isEmpty {
                Text("Aucun vieux correspondant trouvé.")
                    .padding(.leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(oldsList, id: \.annonceId) { old in
                            NavigationLink(destination: MeetingDetailView(matchingOld: old)) {
                                VStack(alignment: .leading) {
                                    Text("\(old.firstName) \(old.lastName)")
                                        .font(.headline)
                                    Text(old.address)
                                        .font(.subheadline)
                                    Text("Distance: \(String(format: "%.1f", old.distance)) km")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
    }
}
