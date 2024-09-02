//
//  HomeNextVisitView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/29/24.
//

import SwiftUI

struct HomeNextVisitView: View {
    var nearestMeeting: Meeting
    var defaultImage: Image

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prochaine visite")
                .font(.headline)
                .padding(.top)
                .padding(.leading)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if let photoURL = nearestMeeting.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        defaultImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading) {
                        Text(nearestMeeting.oldName)
                            .font(.headline)
                        Text("\(nearestMeeting.begin) : \(nearestMeeting.freq)")
                        Text(nearestMeeting.address)
                            .font(.subheadline)
                        Text("Distance: \(nearestMeeting.distance) km")
                    }
                }
                NavigationLink(destination: MeetingDetailView(meeting: nearestMeeting)) {
                    Text("Voir le détail")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
    }
}

