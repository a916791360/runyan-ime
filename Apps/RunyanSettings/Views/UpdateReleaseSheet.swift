import SwiftUI
import RunyanCore

struct UpdateReleaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let release: GitHubRelease

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image("BrandSquare")
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("发现润言新版本")
                        .font(.title2.weight(.bold))
                    Text("最新版本：\(release.displayTitle)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }

            if let bodyText = release.body, !bodyText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("更新内容：")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                    ScrollView {
                        Text(bodyText)
                            .font(.callout)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(height: 200)
                    .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.cardBorder))
                }
            }

            HStack {
                Button("稍后提醒") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("前往 GitHub 下载更新") {
                    NSWorkspace.shared.open(release.htmlUrl)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
