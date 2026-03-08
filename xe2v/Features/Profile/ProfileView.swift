import SwiftUI

struct ProfileView: View {
    @Bindable var env: AppEnvironment
    @Binding var showCompose: Bool

    @State private var vm: ProfileViewModel
    @State private var showLogin = false
    @State private var showSettings = false

    init(env: AppEnvironment, showCompose: Binding<Bool>) {
        self._env = Bindable(env)
        self._showCompose = showCompose
        _vm = State(initialValue: ProfileViewModel(repository: env.repository))
    }

    var body: some View {
        List {
            Section("账号") {
                sessionRow
                if let profile = vm.profile {
                    HStack(spacing: 12) {
                        CachedAsyncImage(urlString: profile.avatarNormal, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.username)
                                .font(.headline)
                            if let tagline = profile.tagline, !tagline.isEmpty {
                                Text(tagline)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("创作") {
                Button("发布主题") {
                    if env.webSession.sessionState.canWrite {
                        showCompose = true
                    } else {
                        env.toastMessage = AppError.unsupportedWriteMode.localizedDescription
                    }
                }
                .disabled(!env.webSession.sessionState.canWrite)

                NavigationLink("草稿箱") {
                    DraftBoxView(env: env)
                }
            }

            Section("我的内容") {
                Text("收藏 / 主题 / 回复入口依赖网页态或后续能力扩展，当前版本提供跳转占位。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("设置") { showSettings = true }
                Button("退出登录", role: .destructive) {
                    Task { await env.webSession.logout() }
                }
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $showLogin) {
            LoginView(env: env)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(env: env)
            }
        }
        .task {
            if case .fullAccess(let username) = env.webSession.sessionState {
                await vm.loadProfile(username: username)
            }
        }
        .onChange(of: env.webSession.sessionState) { _, state in
            Task {
                if case .fullAccess(let username) = state {
                    await vm.loadProfile(username: username)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionRow: some View {
        switch env.webSession.sessionState {
        case .unauthenticated:
            Button("登录") { showLogin = true }
        case .webAuthenticating:
            Label("登录中", systemImage: "clock")
        case .fullAccess(let username):
            HStack {
                Text("已登录：\(username)")
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            }
        case .expired:
            VStack(alignment: .leading, spacing: 4) {
                Text("登录已过期")
                Text("请重新登录以恢复发帖/回复")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("重新登录") { showLogin = true }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 4) {
                Text("登录失败")
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("重试") { showLogin = true }
        }
    }
}
