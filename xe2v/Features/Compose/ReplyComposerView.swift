import SwiftUI

struct ReplyComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var env: AppEnvironment
    let topicID: Int
    let quoteFloor: Int?
    let onSuccess: () -> Void

    @State private var vm: ReplyComposerViewModel

    init(env: AppEnvironment, topicID: Int, quoteFloor: Int?, onSuccess: @escaping () -> Void) {
        self._env = Bindable(env)
        self.topicID = topicID
        self.quoteFloor = quoteFloor
        self.onSuccess = onSuccess
        _vm = State(initialValue: ReplyComposerViewModel(repository: env.repository,
                                                         draftStore: env.drafts,
                                                         topicID: topicID,
                                                         quoteFloor: quoteFloor))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                if let floor = vm.quoteFloor {
                    HStack {
                        Text("引用楼层")
                        Spacer()
                        Text("#\(floor)")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("回复内容")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.content)
                        .frame(minHeight: 200)
                        .font(.body)
                        .padding(8)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                if !env.webSession.sessionState.canWrite {
                    Label(AppError.unsupportedWriteMode.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
                }
                .padding()
            }
            .navigationTitle("写回复")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.posting ? "发布中..." : "发布") {
                        Task {
                            do {
                                try await vm.submit()
                                env.toastMessage = "回复成功"
                                onSuccess()
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
            }
            .onChange(of: vm.content) { _, _ in vm.autoSaveDraft() }
        }
    }
}
