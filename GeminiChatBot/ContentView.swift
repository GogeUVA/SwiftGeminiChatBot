//
//  ContentView.swift
//  GeminiChatBot
//
//  Created by George Yao on 7/14/26.
//

import SwiftUI
import FirebaseAI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    let model = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(modelName: "gemini-3.5-flash")
    
    @State private var chat: Chat?
    @State private var userPrompt = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool
    var body: some View {
        VStack {
            HStack {
                Text("Gemini AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    messages.removeAll()
                    chat = model.startChat()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(messages.isEmpty)
            }
            .padding(.bottom, 8)
            ScrollView {
                LazyVStack(spacing: 12) {

                    if messages.isEmpty {
                        Text("Start a conversation with Gemini.")
                            .foregroundColor(.secondary)
                    }

                    ForEach(messages) { message in

                        HStack {

                            if message.isUser {
                                Spacer()
                            }

                            Text(message.text)
                                .padding()
                                .foregroundColor(message.isUser ? .white : .primary)
                                .background(
                                    message.isUser
                                    ? Color.blue
                                    : Color(.systemGray5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .frame(maxWidth: 280,
                                       alignment: message.isUser ? .trailing : .leading)

                            if !message.isUser {
                                Spacer()
                            }
                        }
                    }

                    if isLoading {
                        ProgressView()
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            HStack {
                TextField("Ask a question...", text: $userPrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .disabled(isLoading)
                    .onSubmit {
                        sendMessage()
                    }
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isLoading ? "ellipsis" : "paperplane.fill")
                        .font(.title2)
                }
                .disabled(userPrompt.isEmpty || isLoading)
            }
        }
        .padding()
        .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onAppear {
                    chat = model.startChat()
                }
    }
    func sendMessage() {
        let prompt = userPrompt
        messages.append(
            ChatMessage(
                text: prompt,
                isUser: true
            )
        )
        userPrompt = ""
        isLoading = true
        Task {
            do {
                guard let chat = chat else {
                    return
                }

                let response = try await chat.sendMessage(prompt)
                messages.append(
                    ChatMessage(
                        text: response.text ?? "No response found",
                        isUser: false
                    )
                )
            }
            catch {
                messages.append(
                    ChatMessage(
                        text: "Error: \(error.localizedDescription)",
                        isUser: false
                    )
                )
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
