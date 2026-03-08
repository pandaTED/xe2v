import SwiftUI

// 兼容模板文件，实际入口是 RootTabView
struct ContentView: View {
    @State private var environment = AppEnvironment()

    var body: some View {
        RootTabView(env: environment)
    }
}

#Preview {
    ContentView()
}
