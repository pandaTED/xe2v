import SwiftUI

struct RootTabView: View {
    @Bindable var env: AppEnvironment

    @State private var selectedTopic: V2EXTopic?
    @State private var showCompose = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(env: env, selectedTopic: $selectedTopic)
            }
            .tabItem {
                Label("首页", systemImage: "house")
            }

            NavigationStack {
                NodesView(env: env, selectedTopic: $selectedTopic)
            }
            .tabItem {
                Label("节点", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                NotificationsView(env: env, selectedTopic: $selectedTopic)
            }
            .tabItem {
                Label("通知", systemImage: "bell")
            }

            NavigationStack {
                ProfileView(env: env, showCompose: $showCompose)
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
        }
        .sheet(item: $selectedTopic) { topic in
            NavigationStack {
                TopicDetailView(env: env, topicID: topic.id)
            }
        }
        .sheet(isPresented: $showCompose) {
            NavigationStack {
                ComposeTopicView(env: env)
            }
        }
        .overlay(alignment: .top) {
            if let message = env.toastMessage {
                Text(message)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            env.toastMessage = nil
                        }
                    }
            }
        }
    }
}
