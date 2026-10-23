import SwiftUI

@main
struct LéksiApp: App {
    var body: some Scene {
        MenuBarExtra("Λέξη", systemImage: "text.bubble") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
