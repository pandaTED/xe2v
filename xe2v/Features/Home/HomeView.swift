import SwiftUI

struct HomeView: View {
    @Bindable var env: AppEnvironment
    @Binding var selectedTopic: V2EXTopic?

    @State private var viewModel: HomeViewModel

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
    }

    private var listView: some View {
        List(viewModel.topics) { topic in
            TopicRowView(topic: topic,
                         isRead: env.readHistory.isRead(topic.id),
                         fontScale: env.settings.fontScale)
                .onTapGesture {
                    env.readHistory.markRead(topicID: topic.id)
                    selectedTopic = topic
                }
                .onAppear {
                    viewModel.loadMoreIfNeeded(current: topic)
                }
                .listRowSeparator(.visible)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.refresh()
        }
    }
}
