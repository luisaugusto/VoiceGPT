import SwiftUI

struct ContentView: View {
    @State private var isReady = false
    @State private var vm = AppViewModel()

    var body: some View {
        ZStack {
            if isReady {
                MainView()
                    .environment(vm)
                    .transition(.opacity)
            } else {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        isReady = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.55), value: isReady)
    }
}
