import SwiftUI

struct ComposeTopicView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var env: AppEnvironment

    @State private var vm: ComposeTopicViewModel

    init(env: AppEnvironment) {
        self._env = Bindable(env)
        _vm = State(initialValue: ComposeTopicViewModel(repository: env.repository, draftStore: env.drafts))
    }

    var body: some View {
        Form {
            Section("节点") {
                if case .loaded = vm.state {
                    Picker("选择节点", selection: $vm.nodeName) {
                        Text("请选择").tag("")
                        ForEach(vm.nodes, id: \.name) { node in
                            Text("\(node.title) (\(node.name))").tag(node.name)
                        }
                    }
                } else if case .failed(let message) = vm.state {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("节点加载失败")
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("重试") { Task { await vm.loadNodes() } }
                    }
                } else {
                    ProgressView()
                }
            }

            Section("标题") {
                TextField("输入标题", text: $vm.title)
                    .textInputAutocapitalization(.never)
            }

            Section("正文（支持基础 Markdown）") {
                TextEditor(text: $vm.content)
                    .frame(minHeight: 220)
                    .font(.body)
            }

            if !env.webSession.sessionState.canWrite {
                Section {
                    Label(AppError.unsupportedWriteMode.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("新主题")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(vm.posting ? "发布中..." : "发布") {
                    Task {
                        do {
                            try await vm.submit()
                            env.toastMessage = "发布成功"
                            dismiss()
                        } catch {
                            env.showError(error)
                        }
                    }
                }
                .disabled(vm.posting || !env.webSession.sessionState.canWrite)
            }
        }
        .task {
            vm.loadDraft()
            if vm.state == .idle {
                await vm.loadNodes()
            }
        }
        .onChange(of: vm.title) { _, _ in vm.autoSaveDraft() }
        .onChange(of: vm.content) { _, _ in vm.autoSaveDraft() }
        .onChange(of: vm.nodeName) { _, _ in vm.autoSaveDraft() }
    }
}
