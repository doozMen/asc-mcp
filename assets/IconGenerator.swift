// Icon Generator for App Store Connect MCP Plugin
// Generates a 1024x1024px PNG icon with App Store Connect branding
// Run: swift IconGenerator.swift

import AppKit
import Foundation

print("App Store Connect MCP Plugin - Icon Generator")
print("═══════════════════════════════════════════════")
print("")

let size = CGSize(width: 1024, height: 1024)

// Generate icon
print("Generating icon (1024x1024px)...")
let image = IconGenerator.generateIcon(size: size)

// Save to assets directory
let currentFileURL = URL(fileURLWithPath: #file)
let assetsDir = currentFileURL.deletingLastPathComponent()
let outputURL = assetsDir.appendingPathComponent("icon.png")

print("Saving to: \(outputURL.path)")

if let data = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: data),
   let png = bitmap.representation(using: .png, properties: [:])
{
    do {
        try png.write(to: outputURL)
        print("✓ Icon saved successfully!")
        print("")
        print("Icon details:")
        print("  Path: \(outputURL.path)")
        print("  Size: \(size.width)x\(size.height)px")

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path))?[.size] as? Int ?? 0
        let fileSizeKB = Double(fileSize) / 1024.0
        print("  File size: \(String(format: "%.1f", fileSizeKB)) KB")
        print("")
        print("Next steps:")
        print("  1. Review icon: open \(outputURL.path)")
        print("  2. Commit to git:")
        print("     git add assets/icon.png")
        print("     git commit -m 'feat(assets): add plugin marketplace icon'")
        print("     git push origin main")
        print("  3. Update plugin.json with GitHub raw URL")
        print("")
    } catch {
        print("✗ Failed to save icon: \(error)")
        exit(1)
    }
} else {
    print("✗ Failed to generate PNG data")
    exit(1)
}

struct IconGenerator {
    static func generateIcon(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        // Draw icon with App Store Connect theme
        Self.drawBackground(in: NSRect(origin: .zero, size: size))
        Self.drawSymbol(in: NSRect(origin: .zero, size: size))
        Self.drawText(in: NSRect(origin: .zero, size: size))

        image.unlockFocus()
        return image
    }

    static func drawBackground(in rect: NSRect) {
        // App Store Connect blue gradient
        let startColor = NSColor(
            calibratedRed: 0.0,
            green: 0.48,
            blue: 1.0,
            alpha: 1.0
        )  // #007AFF
        let endColor = NSColor(
            calibratedRed: 0.0,
            green: 0.32,
            blue: 0.84,
            alpha: 1.0
        )  // Darker blue

        let gradient = NSGradient(colors: [startColor, endColor])

        // iOS app icon rounded corners (22.2% of width)
        let cornerRadius = rect.width * 0.222
        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )

        gradient?.draw(in: rect, angle: 270)
        path.addClip()
    }

    static func drawSymbol(in rect: NSRect) {
        // Draw a simple dSYM file icon symbol
        let symbolSize = rect.width * 0.4
        let symbolRect = NSRect(
            x: (rect.width - symbolSize) / 2,
            y: (rect.height - symbolSize) / 2 + rect.height * 0.1,
            width: symbolSize,
            height: symbolSize
        )

        // Document icon shape
        let path = NSBezierPath()

        // Main rectangle
        let docRect = symbolRect
        path.appendRect(docRect)

        // Folded corner (top-right)
        let foldSize = symbolSize * 0.15
        let foldPath = NSBezierPath()
        foldPath.move(to: NSPoint(x: docRect.maxX - foldSize, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY - foldSize))
        foldPath.close()

        // Draw with white fill and slight transparency
        NSColor.white.withAlphaComponent(0.9).setFill()
        path.fill()

        // Draw fold with darker shade
        NSColor.white.withAlphaComponent(0.7).setFill()
        foldPath.fill()

        // Draw outline
        NSColor.white.withAlphaComponent(0.5).setStroke()
        path.lineWidth = 3
        path.stroke()
    }

    static func drawText(in rect: NSRect) {
        // Draw "dSYM" text
        let text = "dSYM"
        let fontSize = rect.width * 0.12
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: rect.minX,
            y: rect.minY + (rect.height * 0.25) - textSize.height / 2,
            width: rect.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        // Draw subtitle
        let subtitle = "App Store Connect"
        let subtitleFont = NSFont.systemFont(ofSize: fontSize * 0.4, weight: .medium)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .paragraphStyle: paragraphStyle,
        ]

        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleRect = NSRect(
            x: rect.minX,
            y: textRect.minY - subtitleSize.height - 10,
            width: rect.width,
            height: subtitleSize.height
        )

        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
    }
}
