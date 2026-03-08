import SwiftUI

struct TopicDetailView: View {
    @Bindable var env: AppEnvironment
    let topicID: Int

    @State private var viewModel: TopicDetailViewModel
    @State private var showReplyComposer = false
    @State private var jumpToFloor: String = ""
    @State private var showBackToTop = false
    @State private var selectedUsername: String?

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
        .sheet(item: Binding(
            get: { selectedUsername.map(UsernameItem.init) },
            set: { selectedUsername = $0?.value }
        )) { item in
            NavigationStack {
                MemberProfileView(env: env, username: item.value)
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
                                Button(topic.member.username) {
                                    selectedUsername = topic.member.username
                                }
                                .buttonStyle(.plain)
                                Text("·")
                                Text(topic.createdAt.relativeCN)
                                Spacer()
                                Text(topic.node.title)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            PostBodyView(markdownOrPlain: topic.content ?? HTMLContentRenderer.plainText(from: topic.contentRendered),
                                         rawHTML: topic.contentRendered)
                        }
                        .id("topic-top")
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
                                         onTapUser: {
                                             selectedUsername = reply.member.username
                                         },
                                         onQuote: {
                                             viewModel.quoteFloor = index + 1
                                             showReplyComposer = true
                                         })
                            .onAppear {
                                viewModel.loadMoreIfNeeded(lastVisible: reply)
                                showBackToTop = index > 6
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.load(reset: true)
            }
            .overlay(alignment: .bottomTrailing) {
                if showBackToTop {
                    Button {
                        withAnimation {
                            proxy.scrollTo("topic-top", anchor: .top)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline)
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                    .padding(16)
                }
            }
        }
    }
}

private struct UsernameItem: Identifiable {
    var id: String { value }
    let value: String
}
