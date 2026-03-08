import SwiftUI

struct StateView: View {
    let state: LoadState
    var retry: (() -> Void)?

    var body: some View {
        switch state {
        case .idle:
            VStack(spacing: 12) {
                ProgressView()
                Text("正在加载...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("正在加载...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        case .loaded:
            EmptyView()
        case .empty(let message):
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title3)
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                if let retry {
                    Button("重试") { retry() }
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }
}
