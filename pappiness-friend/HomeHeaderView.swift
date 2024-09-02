//
//  HomeHeaderView.swift
//  pappiness-friend
//
//  Created by Lucas on 7/29/24.
//

import SwiftUI

struct HomeHeaderView: View {
    var user: UserData

    var body: some View {
        VStack(alignment: .leading) {
            Text("Bonjour \(user.firstName),")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.leading)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
        }
        .frame(height: 80)
    }
}
