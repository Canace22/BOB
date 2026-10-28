import AppKit

// Diagnostic pose guide only. Never a game art asset.
let size = 1600, cell = 400.0
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.white.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
func point(_ x: Double, _ y: Double, _ i: Int) -> NSPoint {
    NSPoint(x: Double(i % 4) * cell + x, y: Double(size) - (Double(i / 4) * cell + y))
}
func line(_ pts: [(Double, Double)], _ color: NSColor, _ width: Double, _ i: Int) {
    let p = NSBezierPath(); p.lineWidth = width; p.lineCapStyle = .round; p.lineJoinStyle = .round
    p.move(to: point(pts[0].0, pts[0].1, i))
    for v in pts.dropFirst() { p.line(to: point(v.0, v.1, i)) }
    color.setStroke(); p.stroke()
}
func leg(_ phase: Double, _ hip: (Double, Double), _ color: NSColor, _ i: Int) {
    // Six stance samples and ten recovery samples allow brief flight between contacts.
    let support = phase < 0.375
    let t = support ? phase / 0.375 : (phase - 0.375) / 0.625
    let fx = support ? 268 - 136 * t : 132 + 136 * t
    let fy = support ? 340.0 : 340 - 75 * sin(Double.pi * t)
    // Two-segment IK, constant lengths; choose forward-bending knee.
    let dx = fx - hip.0, dy = fy - hip.1, length = 88.0
    let d = min(sqrt(dx*dx + dy*dy), 2*length - 0.01)
    let bend = sqrt(max(0, length*length - d*d/4))
    let kx = (hip.0+fx)/2 + dy/d*bend, ky = (hip.1+fy)/2 - dx/d*bend
    line([hip,(kx,ky),(fx,fy),(fx+24,fy)], color, 11, i)
}
for i in 0..<16 {
    let phase = Double(i)/16.0
    let hip = (195.0, 208.0 - 8*cos(phase*4*Double.pi))
    line([(40,340),(360,340)], .lightGray, 2, i)
    leg((phase+0.5).truncatingRemainder(dividingBy: 1), hip, NSColor.systemBlue, i)
    line([hip,(212,145),(225,119)], .darkGray, 13, i)
    let head = NSBezierPath(ovalIn: NSRect(x: point(204, 135, i).x, y: point(204, 135, i).y, width: 70, height: 70))
    NSColor.darkGray.setStroke(); head.lineWidth = 5; head.stroke()
    line([(265,100),(280,100)], .darkGray, 5, i)
    line([(213,147),(250,193),(285,171)], .darkGray, 10, i)
    leg(phase, hip, NSColor.systemRed, i)
    let label = String(format: "%02d", i+1)
    label.draw(at: point(20,40,i), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 22), .foregroundColor: NSColor.darkGray])
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
