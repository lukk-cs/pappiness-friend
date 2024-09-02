import SwiftUI
import Firebase
import GooglePlaces
import FacebookCore
import GoogleSignIn

@main
struct pappiness_friendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var userManager = UserManager()
    @StateObject private var meetingManager = MeetingManager()
    @StateObject private var matchingOldManager = MatchingOldManager()

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(userManager)
                .environmentObject(meetingManager)
                .environmentObject(matchingOldManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configuration de Firebase
        FirebaseApp.configure()
        print("Firebase configured")
        
        // Configuration de Google Places
        GMSPlacesClient.provideAPIKey("AIzaSyDrndnB5quRS2GsmtH9raYqWCjayHJGRXE")
        print("Google Places configured")
        
        // Initialisation du SDK Facebook
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        print("Facebook SDK configured")
        
        // Activer les logs pour les contraintes insatisfaisables
        UserDefaults.standard.set(true, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Gérer l'ouverture des URL pour Google Sign-In et Facebook
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Gérer les notifications push reçues, si nécessaire
        completionHandler(.newData)
    }
}
