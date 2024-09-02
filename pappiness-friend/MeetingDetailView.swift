//
//  MeetingDetail.swift
//  pappiness-friend
//
//  Created by Lucas on 6/27/24.
//

import SwiftUI

struct MeetingDetailView: View {
    var meeting: Meeting?
    var matchingOld: MatchingOld?
    @EnvironmentObject var manager: MatchingOldManager
    @EnvironmentObject var userManager: UserManager  // Add the UserManager environment object

    var body: some View {
        VStack {
            if let meeting = meeting {
                Text(meeting.oldName)
                    .font(.largeTitle)
                Text(meeting.address)
                    .font(.title)
                Text("Distance: \(meeting.distance) km")
                Text("Fréquence: \(meeting.freq)")
                Text("Début: \(meeting.begin)")
            }
            
            if let old = matchingOld {
                Text("\(old.firstName) \(old.lastName)")
                    .font(.largeTitle)
                Text(old.address)
                    .font(.title)
                Text("Distance: \(String(format: "%.1f", old.distance)) km")
                
                // Add Accept and Decline buttons only if matchingOld is present
                HStack {
                    Button(action: {
                        Task {
                            if let uidYoung = userManager.user?.uid {
                                await manager.handleAcceptOffer(uidYoung: uidYoung, old: old) // Use the current user's uid
                            }
                        }
                    }) {
                        Text("Accepter")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button(action: {
                        Task {
                            if let uidYoung = userManager.user?.uid {
                                await manager.handleDeclineOffer(annonceId: old.annonceId, uidYoung: uidYoung) // Use the current user's uid
                            }
                        }
                    }) {
                        Text("Refuser")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Détails")
        .padding()
    }
}
