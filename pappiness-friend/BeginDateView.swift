//
//  BeginDateView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/7/24.
//

import SwiftUI

struct BeginDateView: View {
    @State private var selectedStartDate: Date?
    @State private var startDate: String = ""

    var name: String
    var uid: String

    var body: some View {
        VStack {
            DatePicker(
                "Select Start Date",
                selection: Binding(get: { selectedStartDate ?? Date() }, set: { newValue in
                    selectedStartDate = newValue
                    startDate = formatDate(date: newValue)
                }),
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()

            Text("Rémunération horaire : 13,50€")
                .padding()

            Spacer()

            NavigationLink(destination: FrequencyView(name: name, uid: uid, startDate: startDate)) {
                Text("Faire une demande")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(startDate.isEmpty)
        }
        .navigationTitle("Begin Date")
    }

    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct BeginDateView_Previews: PreviewProvider {
    static var previews: some View {
        BeginDateView(name: "John Doe", uid: "12345")
    }
}
