//
//  VisitView.swift
//  pappiness-friend
//
//  Created by Lucas on 6/26/24.
//

import SwiftUI

struct VisitsView: View {
    @State private var navigateToBeginDate = false
    var user: UserData
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                NavigationLink(value: navigateToBeginDate) {
                    Button(action: {
                        navigateToBeginDate = true
                    }) {
                        Text("Modifier mes disponibilités")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Visites")
            .navigationDestination(isPresented: $navigateToBeginDate) {
                BeginDateView(name: user.firstName, uid: user.uid)
            }
        }
    }
}

struct VisitsView_Previews: PreviewProvider {
    static var previews: some View {
        VisitsView(user: UserData.dummy)
    }
}
