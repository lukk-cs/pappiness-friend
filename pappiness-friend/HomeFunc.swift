//
//  HomeFunc.swift
//  pappiness-friend
//
//  Created by Lucas on 6/26/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine
import CoreLocation


struct HomeFunc {
    static func getCurrentDayOrder() -> [String] {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.weekday, from: currentDate) - 1 // Sunday = 1, Monday = 2, etc.

        let daysOrder = ["Dimanche matin", "Dimanche midi", "Dimanche après-midi", "Dimanche soir",
                         "Lundi matin", "Lundi midi", "Lundi après-midi", "Lundi soir",
                         "Mardi matin", "Mardi midi", "Mardi après-midi", "Mardi soir",
                         "Mercredi matin", "Mercredi midi", "Mercredi après-midi", "Mercredi soir",
                         "Jeudi matin", "Jeudi midi", "Jeudi après-midi", "Jeudi soir",
                         "Vendredi matin", "Vendredi midi", "Vendredi après-midi", "Vendredi soir",
                         "Samedi matin", "Samedi midi", "Samedi après-midi", "Samedi soir"]
        
        let offset = (currentDay) * 4
        return Array(daysOrder[offset..<daysOrder.count] + daysOrder[0..<offset])
    }

    static func countDaysAndHours(availability: [String: Int]) -> (totalDays: Int, totalHours: Int) {
        var daysSet = Set<String>()
        var totalHours = 0

        for (key, value) in availability {
            let day = key.split(separator: " ")[0]
            daysSet.insert(String(day))
            totalHours += value
        }

        return (daysSet.count, totalHours)
    }
    
}
