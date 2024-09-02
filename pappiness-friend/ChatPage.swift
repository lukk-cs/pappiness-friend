//
//  ChatPage.swift
//  pappiness-friend
//
//  Created by Lucas on 7/4/24.
//

import SwiftUI

struct ChatPage: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText: String = ""
    
    var uid_young: String
    var uid_old: String
    var name_old: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        ForEach(viewModel.messages, id: \.id) { message in
                            HStack {
                                if message.senderUid == uid_young {
                                    Spacer()
                                    MessageBubble(message: message.content, isOwnMessage: true)
                                } else {
                                    MessageBubble(message: message.content, isOwnMessage: false)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                }
                .onChange(of: viewModel.messages) {
                    if let lastMessage = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessage, anchor: .bottom)
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button(action: {
                    viewModel.sendMessage(conversationId: viewModel.conversationId, senderUid: uid_young, messageText: messageText)
                    messageText = ""
                }) {
                    Text("Envoyer")
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle(name_old)
        .onAppear {
            viewModel.initializeChat(uid_young: uid_young, uid_old: uid_old)
        }
    }
}

struct MessageBubble: View {
    var message: String
    var isOwnMessage: Bool
    
    var body: some View {
        Text(message)
            .padding(10)
            .background(isOwnMessage ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(isOwnMessage ? .leading : .trailing, 40)
            .padding(.vertical, 5)
    }
}
