import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var env: AppEnvironment

    @State private var username = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("网页登录") {
                    TextField("用户名（可选）", text: $username)
                        .textInputAutocapitalization(.never)
                    Text("请在下方网页完成 V2EX 登录。登录成功后会自动桥接 Cookie 到 App。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    WebLoginBridgeView { cookies in
                        Task {
                            do {
                                try await env.webSession.bridgeCookies(cookies, username: username.isEmpty ? nil : username)
                            } catch {
                                env.showError(error)
                            }
                        }
                    }
                    .frame(height: 420)
                }

                Section {
                    Button("完成") {
                        if env.webSession.sessionState.canWrite {
                            dismiss()
                        } else {
                            env.toastMessage = "尚未检测到可用登录态"
                        }
                    }
                }
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
