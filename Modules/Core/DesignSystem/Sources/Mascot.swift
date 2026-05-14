import SwiftUI

// MARK: - JellyG mascot (original abstract jelly cube — not modeled on any other product)

public struct JellyG: View {
    public enum Mood { case happy, wow, sad }

    private let size: CGFloat
    private let color: Color
    private let mood: Mood
    @Environment(\.palette) private var palette
    @State private var bobUp = false

    public init(size: CGFloat = 88, color: Color? = nil, mood: Mood = .happy) {
        self.size = size
        self.color = color ?? Color(hex: 0xC8FF3D)
        self.mood = mood
    }

    public var body: some View {
        let ink = palette.ink
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 100.0
            // shadow under
            context.fill(
                Path(ellipseIn: CGRect(x: 20 * scale, y: 90.8 * scale, width: 60 * scale, height: 6.4 * scale)),
                with: .color(.black.opacity(0.16))
            )
            // body — rounded jelly cube
            var body = Path()
            body.move(to: CGPoint(x: 50 * scale, y: 8 * scale))
            body.addCurve(to: CGPoint(x: 90 * scale, y: 48 * scale),
                          control1: CGPoint(x: 75 * scale, y: 8 * scale),
                          control2: CGPoint(x: 90 * scale, y: 22 * scale))
            body.addCurve(to: CGPoint(x: 78 * scale, y: 86 * scale),
                          control1: CGPoint(x: 90 * scale, y: 64 * scale),
                          control2: CGPoint(x: 86 * scale, y: 78 * scale))
            body.addCurve(to: CGPoint(x: 50 * scale, y: 92 * scale),
                          control1: CGPoint(x: 70 * scale, y: 92 * scale),
                          control2: CGPoint(x: 62 * scale, y: 92 * scale))
            body.addCurve(to: CGPoint(x: 22 * scale, y: 86 * scale),
                          control1: CGPoint(x: 38 * scale, y: 92 * scale),
                          control2: CGPoint(x: 30 * scale, y: 92 * scale))
            body.addCurve(to: CGPoint(x: 10 * scale, y: 48 * scale),
                          control1: CGPoint(x: 14 * scale, y: 78 * scale),
                          control2: CGPoint(x: 10 * scale, y: 64 * scale))
            body.addCurve(to: CGPoint(x: 50 * scale, y: 8 * scale),
                          control1: CGPoint(x: 10 * scale, y: 22 * scale),
                          control2: CGPoint(x: 25 * scale, y: 8 * scale))
            body.closeSubpath()
            context.fill(body, with: .color(color))
            context.stroke(body, with: .color(ink), lineWidth: 3.2 * scale)

            // highlight
            var hl = Path()
            hl.move(to: CGPoint(x: 28 * scale, y: 28 * scale))
            hl.addQuadCurve(to: CGPoint(x: 48 * scale, y: 16 * scale),
                            control: CGPoint(x: 34 * scale, y: 16 * scale))
            context.stroke(hl, with: .color(.white.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round))
            context.fill(
                Path(ellipseIn: CGRect(x: 71 * scale, y: 19 * scale, width: 6 * scale, height: 6 * scale)),
                with: .color(.white.opacity(0.7))
            )

            // eyes
            switch mood {
            case .happy:
                drawHappyEye(context: context, x: 38, y: 50, scale: scale, ink: ink)
                drawHappyEye(context: context, x: 62, y: 50, scale: scale, ink: ink)
            case .wow:
                context.fill(Path(ellipseIn: CGRect(x: 34 * scale, y: 46 * scale, width: 8 * scale, height: 8 * scale)),
                             with: .color(ink))
                context.fill(Path(ellipseIn: CGRect(x: 58 * scale, y: 46 * scale, width: 8 * scale, height: 8 * scale)),
                             with: .color(ink))
                context.fill(Path(ellipseIn: CGRect(x: 38 * scale, y: 47 * scale, width: 2.5 * scale, height: 2.5 * scale)),
                             with: .color(.white))
                context.fill(Path(ellipseIn: CGRect(x: 62 * scale, y: 47 * scale, width: 2.5 * scale, height: 2.5 * scale)),
                             with: .color(.white))
            case .sad:
                drawSadEye(context: context, x: 38, y: 52, scale: scale, ink: ink)
                drawSadEye(context: context, x: 62, y: 52, scale: scale, ink: ink)
            }

            // cheeks
            context.fill(
                Path(ellipseIn: CGRect(x: 23 * scale, y: 59 * scale, width: 10 * scale, height: 6 * scale)),
                with: .color(Color(red: 1, green: 90/255, blue: 140/255, opacity: 0.45))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: 67 * scale, y: 59 * scale, width: 10 * scale, height: 6 * scale)),
                with: .color(Color(red: 1, green: 90/255, blue: 140/255, opacity: 0.45))
            )

            // G letter
            context.draw(
                Text("G").font(.custom("Jua", size: 22 * scale))
                    .fontWeight(.heavy)
                    .foregroundStyle(ink),
                at: CGPoint(x: 50 * scale, y: 70 * scale)
            )
        }
        .frame(width: size, height: size)
        .scaleEffect(y: bobUp ? 0.97 : 1, anchor: .bottom)
        .offset(y: bobUp ? -6 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                bobUp = true
            }
        }
    }

    private func drawHappyEye(context: GraphicsContext, x: CGFloat, y: CGFloat, scale: CGFloat, ink: Color) {
        var path = Path()
        path.move(to: CGPoint(x: (x - 4) * scale, y: y * scale))
        path.addQuadCurve(
            to: CGPoint(x: (x + 4) * scale, y: y * scale),
            control: CGPoint(x: x * scale, y: (y - 4) * scale)
        )
        context.stroke(path, with: .color(ink),
                       style: StrokeStyle(lineWidth: 3.5 * scale, lineCap: .round))
    }

    private func drawSadEye(context: GraphicsContext, x: CGFloat, y: CGFloat, scale: CGFloat, ink: Color) {
        var path = Path()
        path.move(to: CGPoint(x: (x - 4) * scale, y: y * scale))
        path.addQuadCurve(
            to: CGPoint(x: (x + 4) * scale, y: y * scale),
            control: CGPoint(x: x * scale, y: (y + 4) * scale)
        )
        context.stroke(path, with: .color(ink),
                       style: StrokeStyle(lineWidth: 3.5 * scale, lineCap: .round))
    }
}
