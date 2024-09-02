//
//  HomeUpcomingVisitsView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/29/24.
//

import SwiftUI

struct HomeUpcomingVisitsView: View {
    var meetings: [Meeting]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Visites à venir:")
                .font(.headline)
                .padding(.top)
                .padding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(meetings.sorted(by: { $0.begin < $1.begin })) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            VStack(alignment: .leading) {
                                Text(meeting.oldName)
                                    .font(.headline)
                                Text("\(meeting.begin) : \(meeting.freq)")
                                Text(meeting.address)
                                    .font(.subheadline)
                                Text("Distance: \(meeting.distance) km")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .frame(width: 200)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
    }
}
