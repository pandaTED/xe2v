import SwiftUI

struct NodesView: View {
    @Bindable var env: AppEnvironment
    @Binding var selectedTopic: V2EXTopic?
    @State private var viewModel: NodesViewModel

    init(env: AppEnvironment, selectedTopic: Binding<V2EXTopic?>) {
        self._env = Bindable(env)
        self._selectedTopic = selectedTopic
        _viewModel = State(initialValue: NodesViewModel(repository: env.repository))
    }

    var body: some View {
        Group {
            if case .loaded = viewModel.state {
                List {
                    if viewModel.searchText.isEmpty, !env.favorites.nodes.isEmpty {
                        Section("已收藏") {
                            ForEach(env.favorites.nodes) { item in
                                NavigationLink {
                                    NodeDetailView(env: env,
                                                   node: .init(id: 0, name: item.name, title: item.title, titleAlternative: nil, url: nil, topics: nil, avatarMini: nil, avatarNormal: nil, avatarLarge: nil, header: nil, footer: nil),
                                                   selectedTopic: $selectedTopic)
                                } label: {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                            Text(item.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section("全部节点") {
                        ForEach(viewModel.filteredNodes) { node in
                            NavigationLink {
                                NodeDetailView(env: env, node: node, selectedTopic: $selectedTopic)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(node.title)
                                        .font(.body)
                                    Text(node.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(env.favorites.contains(node.name) ? "取消收藏" : "收藏") {
                                    env.favorites.toggle(node: node)
                                }
                                .tint(env.favorites.contains(node.name) ? .gray : .yellow)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                StateView(state: viewModel.state) {
                    Task { await viewModel.load() }
                }
            }
        }
        .navigationTitle("节点")
        .searchable(text: $viewModel.searchText, prompt: "搜索节点")
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
                env.favorites.update(from: viewModel.allNodes)
            }
        }
        .onAppear {
            if viewModel.state == .idle {
                Task {
                    await viewModel.load()
                    env.favorites.update(from: viewModel.allNodes)
                }
            } else {
                env.favorites.update(from: viewModel.allNodes)
            }
        }
    }
}
