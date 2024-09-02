//
//  FrequencyView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/8/24.
//

import SwiftUI

struct FrequencyView: View {
    @State private var frequency: String = ""

    var name: String
    var uid: String
    var startDate: String

    var body: some View {
        VStack {
            Button(action: {
                frequency = "reguliere"
            }) {
                Text("Visites régulières")
                    .padding()
                    .background(frequency == "reguliere" ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                frequency = "ponctuelle"
            }) {
                Text("Visites ponctuelles")
                    .padding()
                    .background(frequency == "ponctuelle" ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()

            NavigationLink(destination: DaysOfWeekView(name: name, uid: uid, startDate: startDate, frequency: frequency)) {
                Text("Valider")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(frequency.isEmpty)
        }
        .navigationTitle("Frequency")
    }
}
