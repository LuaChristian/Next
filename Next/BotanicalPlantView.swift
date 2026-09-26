//
//  BotanicalPlantView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct BotanicalPlantView: View {
    let stage: GardenGrowthStage

    var body: some View {
        Canvas { context, size in
            let ink = NextTheme.botanical
            let stem = ink.opacity(0.90)
            let leaf = ink.opacity(0.78)
            let seed = ink.opacity(0.58)

            let origin = CGPoint(x: size.width * 0.48, y: size.height * 0.92)
            let scale = min(size.width, size.height)

            drawSeed(in: &context, origin: origin, scale: scale, color: seed)

            switch stage {
            case .seedling:
                drawStem(in: &context, from: origin, to: point(0.02, -0.28, origin, scale), color: stem, width: 1.35)
                drawLeaf(in: &context, at: point(0.04, -0.22, origin, scale), size: scale * 0.09, angle: 0.55, color: leaf)
            case .sprout:
                drawStem(in: &context, from: origin, to: point(0.01, -0.46, origin, scale), color: stem, width: 1.4)
                drawLeaf(in: &context, at: point(-0.09, -0.28, origin, scale), size: scale * 0.12, angle: -0.85, color: leaf)
                drawLeaf(in: &context, at: point(0.12, -0.32, origin, scale), size: scale * 0.11, angle: 0.75, color: leaf)
            case .young:
                drawStem(in: &context, from: origin, to: point(-0.01, -0.58, origin, scale), color: stem, width: 1.4)
                drawLeaf(in: &context, at: point(-0.12, -0.28, origin, scale), size: scale * 0.12, angle: -0.9, color: leaf)
                drawLeaf(in: &context, at: point(0.13, -0.32, origin, scale), size: scale * 0.11, angle: 0.8, color: leaf)
                drawLeaf(in: &context, at: point(-0.10, -0.46, origin, scale), size: scale * 0.13, angle: -0.7, color: leaf)
                drawLeaf(in: &context, at: point(0.12, -0.50, origin, scale), size: scale * 0.12, angle: 0.65, color: leaf)
            case .growing:
                drawStem(in: &context, from: origin, to: point(-0.03, -0.68, origin, scale), color: stem, width: 1.5)
                drawStem(in: &context, from: point(-0.01, -0.38, origin, scale), to: point(-0.20, -0.56, origin, scale), color: stem, width: 1.2)
                drawLeaf(in: &context, at: point(-0.14, -0.30, origin, scale), size: scale * 0.12, angle: -1.0, color: leaf)
                drawLeaf(in: &context, at: point(0.15, -0.34, origin, scale), size: scale * 0.12, angle: 0.85, color: leaf)
                drawLeaf(in: &context, at: point(-0.22, -0.54, origin, scale), size: scale * 0.13, angle: -0.95, color: leaf)
                drawLeaf(in: &context, at: point(-0.08, -0.52, origin, scale), size: scale * 0.12, angle: -0.45, color: leaf)
                drawLeaf(in: &context, at: point(0.12, -0.56, origin, scale), size: scale * 0.13, angle: 0.7, color: leaf)
                drawLeaf(in: &context, at: point(0.02, -0.68, origin, scale), size: scale * 0.11, angle: 0.15, color: leaf)
            case .mature:
                drawStem(in: &context, from: origin, to: point(-0.02, -0.74, origin, scale), color: stem, width: 1.6)
                drawStem(in: &context, from: point(-0.01, -0.34, origin, scale), to: point(-0.24, -0.60, origin, scale), color: stem, width: 1.25)
                drawStem(in: &context, from: point(-0.01, -0.42, origin, scale), to: point(0.22, -0.64, origin, scale), color: stem, width: 1.25)
                drawLeaf(in: &context, at: point(-0.15, -0.28, origin, scale), size: scale * 0.12, angle: -1.05, color: leaf)
                drawLeaf(in: &context, at: point(0.16, -0.30, origin, scale), size: scale * 0.12, angle: 0.95, color: leaf)
                drawLeaf(in: &context, at: point(-0.26, -0.56, origin, scale), size: scale * 0.14, angle: -1.05, color: leaf)
                drawLeaf(in: &context, at: point(-0.14, -0.58, origin, scale), size: scale * 0.12, angle: -0.45, color: leaf)
                drawLeaf(in: &context, at: point(0.24, -0.60, origin, scale), size: scale * 0.14, angle: 0.95, color: leaf)
                drawLeaf(in: &context, at: point(0.10, -0.62, origin, scale), size: scale * 0.12, angle: 0.35, color: leaf)
                drawLeaf(in: &context, at: point(-0.10, -0.70, origin, scale), size: scale * 0.12, angle: -0.35, color: leaf)
                drawLeaf(in: &context, at: point(0.04, -0.76, origin, scale), size: scale * 0.11, angle: 0.12, color: leaf)
            }
        }
        .accessibilityHidden(true)
        .accessibilityIdentifier("plantStage-\(stage.rawValue)")
    }

    private func point(_ x: CGFloat, _ y: CGFloat, _ origin: CGPoint, _ scale: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    private func drawSeed(
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        color: Color
    ) {
        let rect = CGRect(
            x: origin.x - scale * 0.045,
            y: origin.y - scale * 0.02,
            width: scale * 0.09,
            height: scale * 0.045
        )
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func drawStem(
        in context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        width: CGFloat
    ) {
        var path = Path()
        path.move(to: start)
        let control = CGPoint(
            x: (start.x + end.x) / 2 + (end.y - start.y) * 0.08,
            y: (start.y + end.y) / 2
        )
        path.addQuadCurve(to: end, control: control)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func drawLeaf(
        in context: inout GraphicsContext,
        at center: CGPoint,
        size: CGFloat,
        angle: CGFloat,
        color: Color
    ) {
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size * 0.45, y: -size * 0.55))
        path.addQuadCurve(to: .zero, control: CGPoint(x: size * 0.45, y: size * 0.35))

        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: angle)
        context.stroke(
            path.applying(transform),
            with: .color(color),
            style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    HStack(alignment: .bottom, spacing: 16) {
        ForEach(GardenGrowthStage.allCases, id: \.self) { stage in
            BotanicalPlantView(stage: stage)
                .frame(width: 56, height: 80)
        }
    }
    .padding()
    .background(Color(red: 0.98, green: 0.97, blue: 0.94))
}
