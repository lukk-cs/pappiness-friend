//
//  ChatViewModel.swift
//  pappiness-friend
//
//  Created by Lucas on 7/4/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var conversationId: String?
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func initializeChat(uid_young: String, uid_old: String) {
        findExistingConversation(uid_young: uid_young, uid_old: uid_old) { [weak self] existingConversationId in
            guard let self = self else { return }
            if let existingConversationId = existingConversationId {
                self.conversationId = existingConversationId
                self.fetchMessages(conversationId: existingConversationId)
            } else {
                self.createConversation(uid_young: uid_young, uid_old: uid_old) { newConversationId in
                    self.conversationId = newConversationId
                }
            }
        }
    }
    
    func fetchMessages(conversationId: String) {
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages").order(by: "timestamp")
        messagesRef.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            self.messages = querySnapshot?.documents.compactMap { document in
                try? document.data(as: Message.self)
            } ?? []
        }
    }
    
    func sendMessage(conversationId: String?, senderUid: String, messageText: String) {
        guard let conversationId = conversationId else { return }
        
        let message = Message(senderUid: senderUid, content: messageText, timestamp: Date().timeIntervalSince1970)
        
        do {
            try db.collection("conversations").document(conversationId).collection("messages").addDocument(from: message)
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    private func findExistingConversation(uid_young: String, uid_old: String, completion: @escaping (String?) -> Void) {
        let conversationsRef = db.collection("conversations").whereField("participants", arrayContains: uid_young)
        
        conversationsRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error finding existing conversation: \(error)")
                completion(nil)
                return
            }
            
            let existingConversationId = querySnapshot?.documents.first { document in
                let participants = document.get("participants") as? [String] ?? []
                return participants.contains(uid_old)
            }?.documentID
            
            completion(existingConversationId)
        }
    }
    
    private func createConversation(uid_young: String, uid_old: String, completion: @escaping (String) -> Void) {
        let conversation = Conversation(participants: [uid_young, uid_old])
        
        do {
            let conversationRef = try db.collection("conversations").addDocument(from: conversation)
            completion(conversationRef.documentID)
        } catch {
            print("Error creating conversation: \(error)")
        }
    }
}
