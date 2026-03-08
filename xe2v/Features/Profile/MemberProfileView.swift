import SwiftUI

struct MemberProfileView: View {
    @Bindable var env: AppEnvironment
    let username: String

    @State private var member: V2EXMember?
    @State private var state: LoadState = .idle

    var body: some View {
        Group {
            if let member {
                List {
                    Section {
                        HStack(spacing: 12) {
                            CachedAsyncImage(urlString: member.avatarLarge ?? member.avatarNormal, size: 64)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(member.username)
                                    .font(.title3.weight(.semibold))
                                if let tagline = member.tagline, !tagline.isEmpty {
                                    Text(tagline)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let bio = member.bio, !bio.isEmpty {
                        Section("简介") {
                            Text(bio)
                        }
                    }

                    Section("链接") {
                        if let url = member.url, let link = URL(string: url) {
                            Link("个人主页", destination: link)
                        }
                        if let website = member.website, let link = URL(string: website) {
                            Link("Website", destination: link)
                        }
                        if let github = member.github, let link = URL(string: "https://github.com/\(github)") {
                            Link("GitHub", destination: link)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                StateView(state: state) {
                    Task { await load() }
                }
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        state = .loading

        if let cached = await env.memberCache.member(username: username) {
            member = cached
            state = .loaded
        }

        do {
            let remote = try await env.repository.profile(username: username)
            member = remote
            state = .loaded
        } catch {
            if member == nil {
                let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
                state = .failed(message: msg)
            }
        }
    }
}
