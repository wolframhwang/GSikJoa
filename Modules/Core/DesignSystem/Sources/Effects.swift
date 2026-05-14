import SwiftUI

// MARK: - BlobBackdrop — soft drifting blobs behind content

public struct BlobBackdrop: View {
    @Environment(\.palette) private var palette
    @State private var drift = false

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                BlobShape()
                    .fill(palette.accent.opacity(0.55))
                    .frame(width: 110, height: 110)
                    .offset(x: geo.size.width - 80, y: 60)
                    .offset(x: drift ? 8 : 0, y: drift ? -12 : 0)
                BlobShape()
                    .fill(palette.info.opacity(0.35))
                    .frame(width: 140, height: 140)
                    .offset(x: -40, y: geo.size.height - 250)
                    .offset(x: drift ? -6 : 0, y: drift ? 10 : 0)
                Circle()
                    .fill(palette.primary.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .offset(x: 40, y: 240)
                Circle()
                    .fill(palette.ink.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .offset(x: geo.size.width - 60, y: 360)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.5),
                      control1: CGPoint(x: w * 0.85, y: 0),
                      control2: CGPoint(x: w, y: h * 0.2))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h),
                      control1: CGPoint(x: w, y: h * 0.85),
                      control2: CGPoint(x: w * 0.85, y: h))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.5),
                      control1: CGPoint(x: w * 0.15, y: h),
                      control2: CGPoint(x: 0, y: h * 0.85))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                      control1: CGPoint(x: 0, y: h * 0.2),
                      control2: CGPoint(x: w * 0.15, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti burst — radial spray on correct answer

public struct ConfettiBurst: View {
    private let isActive: Bool
    @Environment(\.palette) private var palette
    @State private var triggered = false

    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public var body: some View {
        ZStack {
            ForEach(0..<22, id: \.self) { i in
                ConfettiPiece(index: i, palette: palette, animate: triggered)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, new in
            if new {
                triggered = false
                DispatchQueue.main.async {
                    withAnimation(.timingCurve(0.2, 0.8, 0.4, 1, duration: 0.9)) {
                        triggered = true
                    }
                }
            } else {
                triggered = false
            }
        }
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let palette: AppPalette
    let animate: Bool

    private var color: Color {
        let palette = [palette.primary, palette.accent, palette.info, Color(hex: 0xFFD93D)]
        return palette[index % palette.count]
    }

    private var displacement: CGSize {
        let count = 22
        let angle = Double(index) / Double(count) * .pi * 2
        let r = 140 + Double(index % 3) * 30
        return CGSize(width: cos(angle) * r, height: sin(angle) * r - 40)
    }

    private var rotation: Double {
        Double(index) * 33
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 12, height: 16)
            .overlay(
                Rectangle().strokeBorder(.black, lineWidth: 1.5)
            )
            .cornerRadius(3)
            .offset(animate ? displacement : .zero)
            .rotationEffect(.degrees(animate ? rotation : 0))
            .opacity(animate ? 0 : 1)
    }
}

// MARK: - JellyIn entrance modifier

public extension View {
    func jellyIn(trigger: AnyHashable) -> some View {
        modifier(JellyInModifier(trigger: trigger))
    }

    func shake(trigger: Int) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

private struct JellyInModifier: ViewModifier {
    let trigger: AnyHashable
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 0.6 + 0.4 * phase + 0.06 * sin(phase * .pi * 2),
                         y: 1.4 - 0.4 * phase - 0.06 * sin(phase * .pi * 2))
            .offset(y: (1 - phase) * 40)
            .opacity(phase)
            .onAppear {
                phase = 0
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                    phase = 1
                }
            }
            .onChange(of: trigger) { _, _ in
                phase = 0
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                    phase = 1
                }
            }
    }
}

private struct ShakeModifier: ViewModifier {
    let trigger: Int
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, _ in
                Task { @MainActor in
                    let stops: [CGFloat] = [-8, 8, -6, 6, -3, 3, 0]
                    for stop in stops {
                        withAnimation(.linear(duration: 0.05)) { offset = stop }
                        try? await Task.sleep(nanoseconds: 50_000_000)
                    }
                }
            }
    }
}
