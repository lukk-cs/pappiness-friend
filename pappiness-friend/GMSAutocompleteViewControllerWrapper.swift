//
//  GMSAutocompleteViewControllerWrapper.swift
//  pappiness-friend
//
//  Created by Lucas on 6/25/24.
//

import SwiftUI
import GooglePlaces

struct GMSAutocompleteViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var selectedAddress: String
    @Binding var latitude: Double
    @Binding var longitude: Double

    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator
        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        var parent: GMSAutocompleteViewControllerWrapper

        init(_ parent: GMSAutocompleteViewControllerWrapper) {
            self.parent = parent
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            parent.selectedAddress = place.formattedAddress ?? ""
            parent.latitude = place.coordinate.latitude
            parent.longitude = place.coordinate.longitude
            viewController.dismiss(animated: true, completion: nil)
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: \(error.localizedDescription)")
            viewController.dismiss(animated: true, completion: nil)
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}


struct GMSAutocompleteViewControllerWrapper_Previews: PreviewProvider {
    static var previews: some View {
        GMSAutocompleteViewControllerWrapper(selectedAddress: .constant(""), latitude: .constant(0.0), longitude: .constant(0.0))
    }
}

