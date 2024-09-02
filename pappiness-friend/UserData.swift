struct UserData: Codable, Identifiable, Equatable {
    var id: String { uid }
    var uid: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var address: String
    var birthDate: String
    var presentation: String
    var interests: String
    var school: String
    var license: String
    var RIB: String
    var longitude: Double
    var latitude: Double
    var holder: String

    static func == (lhs: UserData, rhs: UserData) -> Bool {
        return lhs.uid == rhs.uid &&
            lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.email == rhs.email &&
            lhs.phone == rhs.phone &&
            lhs.address == rhs.address &&
            lhs.birthDate == rhs.birthDate &&
            lhs.presentation == rhs.presentation &&
            lhs.interests == rhs.interests &&
            lhs.school == rhs.school &&
            lhs.license == rhs.license &&
            lhs.RIB == rhs.RIB &&
            lhs.longitude == rhs.longitude &&
            lhs.latitude == rhs.latitude &&
            lhs.holder == rhs.holder
    }

    // Dummy instance for previews
    static let dummy = UserData(
        uid: "123",
        firstName: "Lucas",
        lastName: "Imren",
        email: "imren@stanford.edu",
        phone: "123-456-7890",
        address: "123 Stanford Ave",
        birthDate: "2000-01-01",
        presentation: "Hello, I'm Lucas!",
        interests: "Coding, Music",
        school: "Stanford",
        license: "Driver's License",
        RIB: "RIB Info",
        longitude: 37.4275,
        latitude: -122.1697,
        holder: "Lucas"
    )
}
