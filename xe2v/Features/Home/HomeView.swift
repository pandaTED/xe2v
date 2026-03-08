import SwiftUI

struct HomeView: View {
    @Bindable var env: AppEnvironment
    @Binding var selectedTopic: V2EXTopic?

    @State private var viewModel: HomeViewModel
    @State private var selectedUsername: String?

    init(env: AppEnvironment, selectedTopic: Binding<V2EXTopic?>) {
        self._env = Bindable(env)
        self._selectedTopic = selectedTopic
        _viewModel = State(initialValue: HomeViewModel(repository: env.repository))
    }

    var body: some View {
        Group {
            if case .loaded = viewModel.state, viewModel.topics.isEmpty {
                StateView(state: .empty(message: "暂无主题"), retry: viewModel.refresh)
            } else if case .loaded = viewModel.state {
                listView
            } else {
                StateView(state: viewModel.state, retry: viewModel.refresh)
            }
        }
        .navigationTitle("V2EX")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("流", selection: Binding(get: {
                    viewModel.feedType
                }, set: { newValue in
                    viewModel.switchFeed(newValue)
                })) {
                    ForEach(TopicFeedType.allCases) { feed in
                        Text(feed.rawValue).tag(feed)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .task {
            if viewModel.state == .idle {
                viewModel.refresh()
            }
        }
        .onAppear {
            if viewModel.state == .idle {
                viewModel.refresh()
            }
        }
        .sheet(item: Binding(
            get: { selectedUsername.map(UsernameSelect.init) },
            set: { selectedUsername = $0?.value }
        )) { item in
            NavigationStack {
                MemberProfileView(env: env, username: item.value)
            }
        }
    }

    private var listView: some View {
        List {
            if !env.favorites.nodes.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickNodeChip(title: "全部", nodeName: nil)
                            ForEach(env.favorites.nodes) { item in
                                quickNodeChip(title: item.title, nodeName: item.name)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            ForEach(viewModel.topics) { topic in
                TopicRowView(topic: topic,
                             isRead: env.readHistory.isRead(topic.id),
                             fontScale: env.settings.fontScale,
                             onTapUser: { selectedUsername = topic.member.username })
                    .onTapGesture {
                        env.readHistory.markRead(topicID: topic.id)
                        selectedTopic = topic
                    }
                    .onAppear {
                        viewModel.loadMoreIfNeeded(current: topic)
                    }
                    .listRowSeparator(.visible)
            }

            if viewModel.hasMore, let last = viewModel.topics.last {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .onAppear {
                    viewModel.loadMoreIfNeeded(current: last)
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.refresh()
        }
    }

    private func quickNodeChip(title: String, nodeName: String?) -> some View {
        let selected = viewModel.selectedQuickNodeName == nodeName
        return Button(title) {
            viewModel.switchQuickNode(nodeName)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12), in: Capsule())
    }
}

private struct UsernameSelect: Identifiable {
    let value: String
    var id: String { value }
}
