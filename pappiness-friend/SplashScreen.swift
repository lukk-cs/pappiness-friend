//
//  SplashScreen.swift
//  pappiness-friend
//
//  Created by Lucas on 29/07/2024.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var opacity = 1.0

    var body: some View {
        if isActive {
            Dashboard()
                .transition(.opacity)
                .environmentObject(UserManager())
                .environmentObject(MeetingManager())
                .environmentObject(MatchingOldManager())
        } else {
            VStack {
                Image("logo") // Assurez-vous que le nom de l'image est correct
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
//                Text("Pappiness Friend")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
            }
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Temps de chargement avant de passer à la vue principale
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Délai pour l'animation de fondu
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}
