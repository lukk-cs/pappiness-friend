import SwiftUI

struct Dashboard: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var meetingManager: MeetingManager
    @EnvironmentObject var matchingOldManager: MatchingOldManager

    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            VStack {
                if userManager.loading || meetingManager.loading || matchingOldManager.isLoading || !userManager.isUserSignedIn {
                    ProgressView()
                        .scaleEffect(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if let user = userManager.user {
                        TabView {
                            HomeView(user: user)
                                .tabItem {
                                    Label("Home", systemImage: "house.fill")
                                }

                            VisitsView(user: user)
                                .tabItem {
                                    Label("Visites", systemImage: "calendar")
                                }

                            MessagesView()
                                .tabItem {
                                    Label("Messages", systemImage: "message.fill")
                                }

                            ProfileView()
                                .tabItem {
                                    Label("Profil", systemImage: "person.fill")
                                }
                        }
                    } else {
                        Text("Utilisateur non connecté")
                            .font(.largeTitle)
                            .padding()
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .onAppear {
                print("Dashboard appeared")
                Task {
                    await userManager.fetchAndSaveUser()
                }
            }
            .onChange(of: userManager.user) { newUser in
                if let user = newUser {
                    print("Fetched user: \(user)")
                    Task {
                        await meetingManager.fetchMeetings(userData: user)
                        await matchingOldManager.fetchMatchingOlds(forUser: user.uid)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: .constant(!userManager.isUserSignedIn), content: {
            LoginView()
                .environmentObject(userManager)
        })
    }

    private func refreshData() async {
        isRefreshing = true
        if let user = userManager.user {
            await userManager.fetchAndSaveUser()
            await meetingManager.fetchMeetings(userData: user)
            await matchingOldManager.fetchMatchingOlds(forUser: user.uid)
        }
        isRefreshing = false
    }
}
