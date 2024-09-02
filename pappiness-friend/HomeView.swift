import SwiftUI

struct HomeView: View {
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var matchingOldManager = MatchingOldManager()
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var meetingManager: MeetingManager
    var user: UserData

    @State private var selectedMeeting: Meeting?
    @State private var selectedOld: MatchingOld?
    @State private var isRefreshing: Bool = false

    var defaultImage: Image {
        Image(systemName: "person.circle.fill")

    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if userManager.signingOut {
                    ProgressView()
                        .scaleEffect(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HomeHeaderView(user: user)
                    
                    ScrollView {
                        VStack(alignment: .leading) {
                            Button(action: {
                                userManager.signOut()
                            }) {
                                Text("Déconnexion")
                                    .foregroundColor(.red)
                                    .padding(.leading)
                                    .padding(.top, 10)
                            }

                            if !documentManager.documentStatus.idExists ||
                               !documentManager.documentStatus.inseeExists ||
                               !documentManager.documentStatus.crimeExists ||
                               !documentManager.documentStatus.RIBExists {
                                VStack {
                                    Text("Téléchargez vos pièces justificatives")
                                        .font(.headline)
                                        .padding(.leading)
                                    NavigationLink(destination: DocumentsView(uid: user.uid)) {
                                        Text("Ajouter mes documents")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .padding()
                                }
                            }

                            if matchingOldManager.isLoading {
                                ProgressView()
                            } else {
                                if !matchingOldManager.hasMadeRequest {
                                    VStack {
                                        Text("Aucune demande trouvée.")
                                            .padding(.leading)
                                        NavigationLink(destination: BeginDateView(name: user.firstName, uid: user.uid)) {
                                            Text("Faire une demande")
                                                .padding()
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                        .padding()
                                    }
                                } else {
                                    if meetingManager.loading {
                                        ProgressView()
                                    } else {
                                        if let nearestMeeting = meetingManager.meetings.sorted(by: { $0.begin < $1.begin }).first {
                                            HomeNextVisitView(nearestMeeting: nearestMeeting, defaultImage: defaultImage)
                                        }

                                        HomeUpcomingVisitsView(meetings: meetingManager.meetings)

                                        HomeSuggestedVisitsView(oldsList: matchingOldManager.oldsList)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .onAppear {
                Task {
                    isRefreshing = true
                    await initializeData()
                    isRefreshing = false
                }
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingDetailView(meeting: meeting)
            }
            .navigationDestination(for: MatchingOld.self) { old in
                MeetingDetailView(matchingOld: old)
            }
        }
    }

    func initializeData() async {
        if let user = userManager.user {
            await userManager.fetchAndSaveUser()
            await documentManager.fetchDocumentStatus(forUser: user.uid)
            await matchingOldManager.checkUserRequestStatus(forUser: user.uid)
            
            await matchingOldManager.fetchMatchingOlds(forUser: user.uid)
            await meetingManager.fetchMeetings(userData: user)
            
            if matchingOldManager.hasMadeRequest {
                await matchingOldManager.fetchMatchingOlds(forUser: user.uid)
                await meetingManager.fetchMeetings(userData: user)
            }
        }
    }

    func refreshData() async {
        isRefreshing = true
        await initializeData()
        isRefreshing = false
    }
}
