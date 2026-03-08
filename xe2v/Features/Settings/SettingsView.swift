import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var env: AppEnvironment

    var body: some View {
        List {
            Section("产品原则") {
                Label("无广告、无推荐算法、无营销推送", systemImage: "shield")
                    .font(.body)
                Text("默认不接入统计 SDK。仅支持本地调试日志开关。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("阅读") {
                HStack {
                    Text("字体大小")
                    Spacer()
                    Text(String(format: "%.1fx", env.settings.fontScale))
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(get: {
                    env.settings.fontScale
                }, set: { newValue in
                    env.settings.fontScale = newValue
                }), in: 0.9 ... 1.4, step: 0.1)

                Picker("图片加载", selection: Binding(get: {
                    env.settings.imagePolicy
                }, set: { newValue in
                    env.settings.imagePolicy = newValue
                })) {
                    ForEach(SettingsStore.ImagePolicy.allCases) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
            }

            Section("缓存与日志") {
                Button("清除缓存") {
                    env.settings.clearCache()
                    env.toastMessage = "缓存已清除"
                }
                Toggle("本地调试日志", isOn: Binding(get: {
                    env.settings.enableLocalDebugLog
                }, set: { newValue in
                    env.settings.enableLocalDebugLog = newValue
                }))
            }

            Section("显示") {
                Text("深色模式跟随系统")
                Text("支持动态字体与 VoiceOver 基础访问")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("关于") {
                Text("CleanV2EX")
                Text("一个干净、快速、无广告的 V2EX 客户端。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Link("V2EX 官网", destination: URL(string: "https://www.v2ex.com")!)
            }
        }
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
            }
        }
    }
}
