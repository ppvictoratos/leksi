import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var translatedText: String?
    @State private var isLoading = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                Text("Λέξη")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            TextField("Type to translate…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($inputFocused)
                .onSubmit { triggerTranslation() }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            if isLoading {
                Divider().padding(.horizontal, 10)
                ProgressView()
                    .scaleEffect(0.6)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            } else if let result = translatedText {
                Divider().padding(.horizontal, 10)
                HStack(alignment: .top, spacing: 8) {
                    Text(result)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy translation")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 300)
        .padding(.bottom, 4)
        .onAppear { inputFocused = true }
    }

    private func triggerTranslation() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let fromGreek = isGreekDominant(text)
        let source = fromGreek ? "el" : "en"
        let target = fromGreek ? "en" : "el"

        isLoading = true
        translatedText = nil

        Task {
            do {
                let result = try await translate(text, from: source, to: target)
                translatedText = result
            } catch {
                translatedText = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func translate(_ text: String, from source: String, to target: String) async throws -> String {
        let url = URL(string: "http://127.0.0.1:5005/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "q": text, "source": source, "target": target, "format": "text"
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONDecoder().decode(TranslationResponse.self, from: data)
        return json.translatedText
    }

    private func isGreekDominant(_ text: String) -> Bool {
        let scalars = text.unicodeScalars
        let greekCount = scalars.filter {
            ($0.value >= 0x0370 && $0.value <= 0x03FF) ||
            ($0.value >= 0x1F00 && $0.value <= 0x1FFF)
        }.count
        let letterCount = scalars.filter { CharacterSet.letters.contains($0) }.count
        return letterCount > 0 && Double(greekCount) / Double(letterCount) > 0.5
    }
}

private struct TranslationResponse: Decodable {
    let translatedText: String
}
