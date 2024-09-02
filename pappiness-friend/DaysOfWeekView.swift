//
//  DaysOfWeekView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/8/24.
//

import SwiftUI

struct DaysOfWeekView: View {
    @State private var selections: [String: [String: Bool]] = [:]

    var name: String
    var uid: String
    var startDate: String
    var frequency: String

    private let daysOfWeek = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    private let moments = ["matin", "midi", "a-m", "soir"]

    var body: some View {
        VStack {
            ForEach(daysOfWeek, id: \.self) { day in
                VStack(alignment: .leading) {
                    Text(day)
                        .font(.headline)

                    HStack {
                        ForEach(moments, id: \.self) { moment in
                            Toggle(isOn: Binding(
                                get: { selections[day]?[moment] ?? false },
                                set: { newValue in
                                    selections[day, default: [:]][moment] = newValue
                                }
                            )) {
                                Text(moment)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                    }
                }
                .padding()
            }

            Spacer()

            NavigationLink(destination: HoursOfDayView(name: name, uid: uid, startDate: startDate, frequency: frequency, chosenMoments: selections)) {
                Text("Faire une demande")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!selections.values.flatMap { $0.values }.contains(true))
        }
        .navigationTitle("Days of Week")
    }
}


struct DaysOfWeekView_Previews: PreviewProvider {
    static var previews: some View {
        DaysOfWeekView(name: "John Doe", uid: "12345", startDate: "2023-07-08", frequency: "reguliere")
    }
}
