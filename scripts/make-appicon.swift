import AppKit
import Foundation

// 从一张方形图标源图生成 macOS 所需的全部尺寸 PNG：
//   1) 自动探测非白内容边界，裁掉四周白边
//   2) 套圆角遮罩（macOS 图标圆角约为边长的 22.37%）
//   3) 按 Assets.xcassets 的命名约定输出
//
// 用法：swift make-appicon.swift <源图> <输出目录>

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("用法: swift make-appicon.swift <源图> <输出目录>\n".data(using: .utf8)!)
    exit(1)
}
let srcPath = args[1]
let outDir = args[2]

_ = NSApplication.shared

guard let srcImage = NSImage(contentsOfFile: srcPath),
      let cg = srcImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("无法读取源图\n".data(using: .utf8)!)
    exit(1)
}

let width = cg.width
let height = cg.height

guard let data = cg.dataProvider?.data, let ptr = CFDataGetBytePtr(data) else {
    FileHandle.standardError.write("无法读取像素\n".data(using: .utf8)!)
    exit(1)
}

let bytesPerRow = cg.bytesPerRow
let bytesPerPixel = max(1, cg.bitsPerPixel / 8)
let threshold = 245

var minX = width, minY = height, maxX = 0, maxY = 0

for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        guard offset + 2 < CFDataGetLength(data) else { continue }
        let r = Int(ptr[offset])
        let g = Int(ptr[offset + 1])
        let b = Int(ptr[offset + 2])
        if r < threshold || g < threshold || b < threshold {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }
}

guard maxX > minX, maxY > minY else {
    FileHandle.standardError.write("没有探测到图标内容\n".data(using: .utf8)!)
    exit(1)
}

let contentWidth = maxX - minX + 1
let contentHeight = maxY - minY + 1
let side = max(contentWidth, contentHeight)
let centerX = (minX + maxX) / 2
let centerY = (minY + maxY) / 2

let cropRect = CGRect(
    x: centerX - side / 2,
    y: centerY - side / 2,
    width: side,
    height: side
)

guard let cropped = cg.cropping(to: cropRect) else {
    FileHandle.standardError.write("裁剪失败\n".data(using: .utf8)!)
    exit(1)
}

print("源图 \(width)x\(height)，内容 \(contentWidth)x\(contentHeight)，按 \(side) 方形裁剪")

let outputs: [(size: Int, name: String)] = [
    (16, "icon_16x16@1x.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32@1x.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128@1x.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256@1x.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512@1x.png"),
    (1024, "icon_512x512@2x.png"),
]

for output in outputs {
    let size = output.size
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { continue }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let radius = CGFloat(size) * 0.2237
    NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)),
        xRadius: radius,
        yRadius: radius
    ).addClip()

    let image = NSImage(cgImage: cropped, size: NSSize(width: side, height: side))
    image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { continue }
    try png.write(to: URL(fileURLWithPath: outDir + "/" + output.name))
    print("  \(output.name)  \(size)x\(size)")
}

print("完成")
