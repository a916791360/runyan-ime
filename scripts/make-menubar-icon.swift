import AppKit
import CoreText
import Foundation

// 生成输入法图标位图或矢量 PDF。模式：
//
//   template（默认）—— 实心圆角方块，字形是**挖空**的（alpha 0），黑色作为遮罩。
//     系统按模板图渲染：菜单栏（深色）染成白方块、字透出壁纸；下拉列表（浅色）
//     染成黑方块、字是浅色；光标悬浮指示器（macOS 14+）染成白方块透出蓝色底。
//     如果输出路径是 .pdf，生成 16×16 pt 的矢量 PDF（EvenOdd 挖空），符合系统模板标准。
//
//   boxed —— 深灰圆角方块 + 白色字形，按原色渲染。给「不认模板」的场合兜底。
//
//   glyph —— 只有字形，底色全透明。系统会整块染白，字就没了，一般不要用。
//
// 尺寸规则：搜狗的菜单图标是 16×16 pt 的矢量 PDF。
//
// 用法：swift make-menubar-icon.swift <输出.png|.pdf> [宽] [高] [template|boxed|glyph]

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("用法: swift make-menubar-icon.swift <输出.png|.pdf> [宽] [高] [template|boxed|glyph]\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = args[1]
let width = args.count >= 3 ? (Int(args[2]) ?? 16) : 16
let height = args.count >= 4 ? (Int(args[3]) ?? 16) : 16
let mode = args.count >= 5 ? args[4] : "template"

_ = NSApplication.shared

if outputPath.hasSuffix(".pdf") {
    let url = URL(fileURLWithPath: outputPath) as CFURL
    var mediaBox = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
    guard let ctx = CGContext(url, mediaBox: &mediaBox, nil) else {
        FileHandle.standardError.write("无法创建 PDF 上下文\n".data(using: .utf8)!)
        exit(1)
    }
    ctx.beginPage(mediaBox: &mediaBox)

    let combinedPath = CGMutablePath()
    let inset: CGFloat = 0.5
    let plate = mediaBox.insetBy(dx: inset, dy: inset)
    let roundRect = CGPath(roundedRect: plate, cornerWidth: plate.width * 0.28, cornerHeight: plate.width * 0.28, transform: nil)
    combinedPath.addPath(roundRect)

    let ctFont = CTFontCreateWithName("PingFangSC-Medium" as CFString, CGFloat(height) * 0.70, nil)
    var unichars = Array("润".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: 1)
    if CTFontGetGlyphsForCharacters(ctFont, &unichars, &glyphs, 1) {
        if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyphs[0], nil) {
            let bbox = glyphPath.boundingBox
            let dx = (CGFloat(width) - bbox.width) / 2.0 - bbox.minX
            let dy = (CGFloat(height) - bbox.height) / 2.0 - bbox.minY
            let t = CGAffineTransform(translationX: dx, y: dy)
            combinedPath.addPath(glyphPath, transform: t)
        }
    }

    ctx.addPath(combinedPath)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1.0))
    ctx.fillPath(using: .evenOdd)

    ctx.endPage()
    ctx.closePDF()
    print("已生成矢量 PDF：\(outputPath)")
    exit(0)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write("无法创建位图\n".data(using: .utf8)!)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

// 正方形区域：高度撑满、水平居中
let square = CGFloat(height)
let rect = NSRect(x: (CGFloat(width) - square) / 2, y: 0, width: square, height: square)

let glyph = "润" as NSString

switch mode {
case "template":
    // 方块铺满画布（留 0.5pt 给抗锯齿），圆弧占 28%——搜狗那个方块量出来就是这个比例。
    let inset: CGFloat = 0.5
    let plate = rect.insetBy(dx: inset, dy: inset)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: plate, xRadius: plate.width * 0.28, yRadius: plate.width * 0.28).fill()

    // 字形挖空：只扣 alpha，颜色留给系统染。
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.66, weight: .bold),
        .foregroundColor: NSColor.black,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    NSGraphicsContext.current?.compositingOperation = .destinationOut
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
    NSGraphicsContext.current?.compositingOperation = .sourceOver

case "glyph":
    // 只有字形。黑色是给「亮色菜单栏」用的；暗色菜单栏系统会自动染白。
    // 字号略小于方块，留一点呼吸，避免和高分屏抗锯齿打架。
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.9, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
default:
    NSColor.black.setFill()
    NSBezierPath(
        roundedRect: rect,
        xRadius: square * 0.22,
        yRadius: square * 0.22
    ).fill()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square * 0.74, weight: .bold),
        .foregroundColor: NSColor.white,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(
            x: rect.midX - glyphSize.width / 2,
            y: rect.midY - glyphSize.height / 2
        ),
        withAttributes: attributes
    )
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("PNG 编码失败\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成 \(width)×\(height) [\(mode)]：\(outputPath)")
