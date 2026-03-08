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
                List(viewModel.filteredNodes) { node in
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
            }
        }
    }
}
