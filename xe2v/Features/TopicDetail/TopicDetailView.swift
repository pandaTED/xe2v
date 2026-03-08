import SwiftUI

struct TopicDetailView: View {
    @Bindable var env: AppEnvironment
    let topicID: Int

    @State private var viewModel: TopicDetailViewModel
    @State private var showReplyComposer = false
    @State private var jumpToFloor: String = ""

    init(env: AppEnvironment, topicID: Int) {
        self._env = Bindable(env)
        self.topicID = topicID
        _viewModel = State(initialValue: TopicDetailViewModel(repository: env.repository, topicID: topicID))
    }

    var body: some View {
        Group {
            if case .loaded = viewModel.state {
                contentView
            } else {
                StateView(state: viewModel.state) {
                    viewModel.load(reset: true)
                }
            }
        }
        .navigationTitle("主题")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("回复") {
                    if env.webSession.sessionState.canWrite {
                        showReplyComposer = true
                    } else {
                        env.toastMessage = AppError.unsupportedWriteMode.localizedDescription
                    }
                }
            }
        }
        .sheet(isPresented: $showReplyComposer) {
            ReplyComposerView(env: env, topicID: topicID, quoteFloor: viewModel.quoteFloor) {
                viewModel.load(reset: true)
            }
        }
        .task {
            if viewModel.state == .idle {
                viewModel.load(reset: true)
            }
        }
        .onAppear {
            if viewModel.state == .idle {
                viewModel.load(reset: true)
            }
        }
    }

    private var contentView: some View {
        ScrollViewReader { proxy in
            List {
                if let topic = viewModel.topic {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(topic.title)
                                .font(.title3.weight(.semibold))
                            HStack {
                                Text(topic.member.username)
                                Text("·")
                                Text(topic.createdAt.relativeCN)
                                Spacer()
                                Text(topic.node.title)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            PostBodyView(markdownOrPlain: topic.content ?? HTMLContentRenderer.plainText(from: topic.contentRendered))
                        }
                        .padding(.vertical, 8)
                    }

                    Section("回复 \(viewModel.replies.count)") {
                        HStack {
                            TextField("跳转楼层", text: $jumpToFloor)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            Button("跳转") {
                                guard let floor = Int(jumpToFloor), floor > 0 else { return }
                                withAnimation {
                                    proxy.scrollTo(floor, anchor: .top)
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        ForEach(Array(viewModel.replies.enumerated()), id: \.element.id) { index, reply in
                            ReplyRowView(reply: reply,
                                         floor: index + 1,
                                         fontScale: env.settings.fontScale,
                                         onQuote: {
                                             viewModel.quoteFloor = index + 1
                                             showReplyComposer = true
                                         })
                            .onAppear {
                                viewModel.loadMoreIfNeeded(lastVisible: reply)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.load(reset: true)
            }
        }
    }
}
