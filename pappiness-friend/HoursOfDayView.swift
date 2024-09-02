//
//  HoursOfDayView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/8/24.
//

import SwiftUI
import Firebase


struct HoursOfDayView: View {
    @State private var selectedHours: [String: Double] = [:]
    @State private var loading = false
    @State private var navigateToSuccess = false
    
    var name: String
    var uid: String
    var startDate: String
    var frequency: String
    var chosenMoments: [String: [String: Bool]]
    
    var body: some View {
        NavigationStack {
            VStack {
                ForEach(chosenMoments.keys.sorted(), id: \.self) { day in
                    VStack(alignment: .leading) {
                        Text(day)
                            .font(.headline)
                        
                        ForEach(chosenMoments[day]!.keys.sorted(), id: \.self) { moment in
                            if chosenMoments[day]![moment] == true {
                                VStack(alignment: .leading) {
                                    Text("\(day) \(moment)")
                                        .font(.subheadline)
                                    
                                    Slider(value: Binding(
                                        get: { selectedHours["\(day) \(moment)"] ?? 1.0 },
                                        set: { newValue in selectedHours["\(day) \(moment)"] = newValue }
                                    ), in: 1...4, step: 0.5)
                                    
                                    Text("Hours: \(selectedHours["\(day) \(moment)"] ?? 1.0, specifier: "%.1f")")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                if loading {
                    ProgressView()
                } else {
                    NavigationLink(value: navigateToSuccess) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        post(name: name, startDate: startDate, frequency: frequency, uid: uid, chosenHours: selectedHours)
                    }) {
                        Text("Finaliser ma demande")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Hours of Day")
            .navigationDestination(isPresented: $navigateToSuccess) {
                SuccessView(name: name, uid: uid)
            }
        }
    }
    
    private func post(name: String, startDate: String, frequency: String, uid: String, chosenHours: [String: Double]) {
        loading = true
        
        let db = Firestore.firestore()
        let annoncesCollection = db.collection("annoncesJeunes")
        
        // Convert chosenHours to the desired format
        var formattedHours: [String: [Double]] = [:]
        for (key, value) in chosenHours {
            formattedHours[key] = [value, 0]
        }
        
        annoncesCollection.whereField("user", isEqualTo: uid).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                loading = false
                return
            }
            
            let batch = db.batch()
            
            querySnapshot?.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error deleting documents: \(error)")
                    loading = false
                    return
                }
                
                annoncesCollection.addDocument(data: [
                    "user": uid,
                    "begin": startDate,
                    "freq": frequency,
                    "hours": formattedHours
                ]) { error in
                    if let error = error {
                        print("Error adding document: \(error)")
                    } else {
                        print("Document successfully added!")
                        navigateToSuccess = true // Trigger navigation to SuccessView
                    }
                    loading = false
                }
            }
        }
    }
}

struct HoursOfDayView_Previews: PreviewProvider {
    static var previews: some View {
        HoursOfDayView(
            name: "John Doe",
            uid: "12345",
            startDate: "2023-07-08",
            frequency: "reguliere",
            chosenMoments: ["Lundi": ["matin": true, "midi": false, "a-m": true, "soir": false]]
        )
    }
}
