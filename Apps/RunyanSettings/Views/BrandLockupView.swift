import SwiftUI

/// 应用内统一的品牌标识：品牌方块 + 「润言」+ 副标题。
///
/// 之前这是一张位图（BrandLockup），字和图都焊死在 PNG 里，
/// 暗色模式还得单独出一张；改成原生视图后，字号、颜色、明暗都跟着主题走。
struct BrandLockupView: View {
    var markSize: CGFloat = 62
    var titleSize: CGFloat = 32
    var subtitle: String = "AI 润色输入法"

    var body: some View {
        HStack(spacing: markSize * 0.22) {
            Image("BrandSquare")
                .resizable()
                .scaledToFit()
                .frame(width: markSize, height: markSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: titleSize * 0.04) {
                Text("润言")
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.system(size: titleSize * 0.44, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("润言 · \(subtitle)")
    }
}
