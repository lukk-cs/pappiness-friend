import SwiftUI
import Firebase
import GoogleSignIn
import FBSDKLoginKit

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loading: Bool = false
    @State private var errorMessage: String?
    @State private var showRegister: Bool = false
    @State private var showingPasswordResetAlert = false

    @EnvironmentObject var userManager: UserManager

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bienvenue")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Se connecter")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                Spacer()

                VStack(alignment: .leading, spacing: 15) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 24)

                HStack {
                    Spacer()
                    Button(action: {
                        showingPasswordResetAlert = true
                    }) {
                        Text("Mot de passe oublié ?")
                            .foregroundColor(Color.customBlue)
                    }
                    .alert(isPresented: $showingPasswordResetAlert) {
                        Alert(
                            title: Text("Réinitialiser le mot de passe"),
                            message: Text("Entrez votre adresse e-mail pour réinitialiser votre mot de passe."),
                            primaryButton: .default(Text("Envoyer")) {
                                resetPassword()
                            },
                            secondaryButton: .cancel(Text("Annuler"))
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 20) {
                    if loading {
                        ProgressView()
                    } else {
                        Button(action: {
                            signIn()
                        }) {
                            Text("Se connecter")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.customBlue)
                                .cornerRadius(8)
                        }
                    }

                    Text("------------- OU -------------")
                        .foregroundColor(.gray)

                    HStack(spacing: 20) {
                        Button(action: {
                            facebookLogin()
                        }) {
                            Image("logo-fb")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        }

                        Button(action: {
                            googleLogin()
                        }) {
                            Image("logo-google")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }

                    HStack {
                        Text("Pas encore de compte ?")
                        Button(action: {
                            showRegister = true
                        }) {
                            Text("S'inscrire")
                                .foregroundColor(Color.customBlue)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarHidden(true)
            .padding(.top, 20)
            .fullScreenCover(isPresented: $showRegister) {
                RegisterView()
            }
            .fullScreenCover(isPresented: $userManager.userSignedIn) {
                Dashboard()
                    .environmentObject(userManager)
            }
        }
    }

    private func signIn() {
        loading = true
        errorMessage = nil

        AuthFunctions.signIn(email: email, password: password) { result in
            loading = false
            switch result {
            case .success:
                print("signed in")
                Task {
                    await userManager.fetchAndSaveUser()
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func googleLogin() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let result = result else { return }

            let idToken = result.user.idToken?.tokenString ?? ""
            let accessToken = result.user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                print("User is signed in")
                Task {
                    await userManager.fetchAndSaveUser()
                }
            }
        }
    }

    private func facebookLogin() {
        let manager = LoginManager()
        manager.logIn(permissions: ["public_profile", "email"], from: getRootViewController()) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let result = result, !result.isCancelled {
                guard let accessToken = AccessToken.current else {
                    self.errorMessage = "Failed to get access token"
                    return
                }

                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    print("User is signed in")
                    Task {
                        await userManager.fetchAndSaveUser()
                    }
                }
            }
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            self.errorMessage = "Veuillez entrer votre adresse e-mail."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = "Un email de réinitialisation de mot de passe a été envoyé."
            }
        }
    }

    private func getRootViewController() -> UIViewController {
        return UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserManager())
    }
}
