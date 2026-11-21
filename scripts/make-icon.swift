// Draws the app icon and writes a 1024px PNG. Usage: swift make-icon.swift <output.png>
// A calendar page in the shared look of the other apps: the days left as a big number,
// and under it the bar that drains as the day comes closer.
import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let inset = 100.0
let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let background = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
NSGradient(colors: [NSColor(red: 0.27, green: 0.22, blue: 0.56, alpha: 1),
                    NSColor(red: 0.10, green: 0.08, blue: 0.24, alpha: 1)])!.draw(in: background, angle: -90)

let violet = NSColor(red: 0.56, green: 0.50, blue: 1.00, alpha: 1)
let mint = NSColor(red: 0.18, green: 0.83, blue: 0.68, alpha: 1)
let amber = NSColor(red: 1.00, green: 0.80, blue: 0.36, alpha: 1)
let ink = NSColor(red: 0.10, green: 0.08, blue: 0.22, alpha: 1)

func pill(_ frame: NSRect, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: frame, xRadius: min(frame.width, frame.height) / 2, yRadius: min(frame.width, frame.height) / 2).fill()
}

// The page, with a dark rim to lift it off the background.
let page = NSRect(x: 232, y: 212, width: 560, height: 580)
let corner = 104.0
ink.withAlphaComponent(0.6).setFill()
NSBezierPath(roundedRect: page.insetBy(dx: -14, dy: -14), xRadius: corner + 14, yRadius: corner + 14).fill()
NSGraphicsContext.saveGraphicsState()
NSBezierPath(roundedRect: page, xRadius: corner, yRadius: corner).addClip()
amber.setFill()
page.fill()
// Header band.
let header = NSRect(x: page.minX, y: page.maxY - 150, width: page.width, height: 150)
violet.setFill()
header.fill()
NSGraphicsContext.restoreGraphicsState()

// Binder rings over the header's top edge.
for x in [page.minX + 150, page.maxX - 150] {
    pill(NSRect(x: x - 24, y: page.maxY - 78, width: 48, height: 124), ink)
    pill(NSRect(x: x - 12, y: page.maxY - 66, width: 24, height: 100), NSColor(white: 1, alpha: 0.9))
}

// Days left.
let font = NSFont.systemFont(ofSize: 300, weight: .heavy)
let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: 300) } ?? font
let number = NSAttributedString(string: "7", attributes: [.font: rounded, .foregroundColor: ink])
let bounds = number.size()
number.draw(at: NSPoint(x: page.midX - bounds.width / 2, y: page.minY + 96))

// Time left on its track.
let track = NSRect(x: page.minX + 70, y: page.minY + 62, width: page.width - 140, height: 40)
pill(track, ink.withAlphaComponent(0.22))
pill(NSRect(x: track.minX, y: track.minY, width: track.width * 0.4, height: track.height), mint)

image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
