//
//  PlantView.swift
//  Next
//
//  Reusable botanical renderer. Identity is the variant; growth is the stage.
//  Artwork comes from PlantArtwork (asset catalog when present, Canvas otherwise).
//  Surfaces (Garden, Goal Detail, Home Garden) only pass variant + stage.
//

import SwiftUI
import UIKit

struct PlantView: View {
    let variant: PlantVariant
    let stage: GardenGrowthStage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            switch PlantArtwork.resolve(variant: variant, stage: stage) {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    // Full-color / line artwork is drawn as authored — never template-tinted.
            case .pixel(let species):
                PixelPlantView(species: species, stage: stage)
            case .canvas:
                Canvas { context, size in
                    PlantDrawing.draw(
                        variant: variant,
                        stage: stage,
                        in: &context,
                        size: size,
                        colorScheme: colorScheme
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
        .accessibilityIdentifier("plant-\(PlantArtwork.signature(variant: variant, stage: stage))")
    }
}

enum PlantDrawing {
    static func draw(
        variant: PlantVariant,
        stage: GardenGrowthStage,
        in context: inout GraphicsContext,
        size: CGSize,
        colorScheme: ColorScheme = .light
    ) {
        let origin = CGPoint(x: size.width * 0.50, y: size.height * 0.93)
        let scale = min(size.width, size.height)
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let resolved = UIColor(NextTheme.botanicalInk)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        let ink = Color(uiColor: resolved)
        drawSeed(in: &context, origin: origin, scale: scale, color: ink.opacity(colorScheme == .dark ? 0.78 : 0.68))

        switch variant {
        case .broadLeaf: drawBroad(stage, in: &context, origin: origin, scale: scale, ink: ink)
        case .narrowLeaf: drawNarrow(stage, in: &context, origin: origin, scale: scale, ink: ink)
        case .branching: drawBranching(stage, in: &context, origin: origin, scale: scale, ink: ink)
        case .roundedLeaf: drawRounded(stage, in: &context, origin: origin, scale: scale, ink: ink)
        }
    }

    static func signature(variant: PlantVariant, stage: GardenGrowthStage) -> String {
        "\(variant.rawValue)-\(stage.rawValue)"
    }

    private static func p(_ x: CGFloat, _ y: CGFloat, _ origin: CGPoint, _ scale: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    private static func drawSeed(
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        color: Color
    ) {
        let rect = CGRect(
            x: origin.x - scale * 0.058,
            y: origin.y - scale * 0.020,
            width: scale * 0.116,
            height: scale * 0.050
        )
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private static func stem(
        in context: inout GraphicsContext,
        from: CGPoint,
        to: CGPoint,
        color: Color,
        width: CGFloat,
        lean: CGFloat = 0.08
    ) {
        var path = Path()
        path.move(to: from)
        path.addQuadCurve(
            to: to,
            control: CGPoint(
                x: (from.x + to.x) / 2 + (to.y - from.y) * lean,
                y: (from.y + to.y) / 2
            )
        )
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private static func leaf(
        in context: inout GraphicsContext,
        at center: CGPoint,
        size: CGFloat,
        angle: CGFloat,
        color: Color,
        shape: LeafShape,
        bias: CGFloat = 0
    ) {
        var path = Path()
        switch shape {
        case .broad:
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: size, y: 0), control: CGPoint(x: size * 0.42, y: -size * 0.62))
            path.addQuadCurve(to: .zero, control: CGPoint(x: size * 0.42, y: size * 0.40))
        case .narrow:
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: size * 1.15, y: 0), control: CGPoint(x: size * 0.55, y: -size * 0.28))
            path.addQuadCurve(to: .zero, control: CGPoint(x: size * 0.55, y: size * 0.22))
        case .rounded:
            // Ovate blade: fuller than Broad, still a leaf — never a circle.
            path.move(to: .zero)
            path.addCurve(
                to: CGPoint(x: size * 0.90, y: -size * (0.08 + bias * 0.45)),
                control1: CGPoint(x: size * (0.18 + bias * 0.55), y: -size * 0.20),
                control2: CGPoint(x: size * (0.58 + bias * 0.28), y: -size * 0.40)
            )
            path.addCurve(
                to: .zero,
                control1: CGPoint(x: size * (0.50 - bias * 0.32), y: size * 0.28),
                control2: CGPoint(x: size * (0.16 - bias * 0.38), y: size * 0.16)
            )
        }

        let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
        context.stroke(
            path.applying(transform),
            with: .color(color),
            style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round)
        )
    }

    private enum LeafShape {
        case broad, narrow, rounded
    }

    private static func drawBroad(
        _ stage: GardenGrowthStage,
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        ink: Color
    ) {
        let o = origin
        let s = scale
        switch stage {
        case .seedling:
            stem(in: &context, from: o, to: p(0.02, -0.38, o, s), color: ink, width: 1.65)
            leaf(in: &context, at: p(0.08, -0.30, o, s), size: s * 0.155, angle: 0.48, color: ink, shape: .broad)
        case .sprout:
            stem(in: &context, from: o, to: p(0.00, -0.48, o, s), color: ink, width: 1.4)
            leaf(in: &context, at: p(-0.11, -0.30, o, s), size: s * 0.13, angle: -0.85, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.13, -0.34, o, s), size: s * 0.13, angle: 0.78, color: ink, shape: .broad)
        case .young:
            stem(in: &context, from: o, to: p(-0.01, -0.60, o, s), color: ink, width: 1.45)
            leaf(in: &context, at: p(-0.14, -0.30, o, s), size: s * 0.13, angle: -0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.15, -0.33, o, s), size: s * 0.13, angle: 0.85, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.12, -0.48, o, s), size: s * 0.14, angle: -0.65, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.13, -0.52, o, s), size: s * 0.14, angle: 0.62, color: ink, shape: .broad)
        case .growing:
            stem(in: &context, from: o, to: p(-0.02, -0.70, o, s), color: ink, width: 1.5)
            stem(in: &context, from: p(-0.01, -0.38, o, s), to: p(-0.20, -0.58, o, s), color: ink, width: 1.2)
            leaf(in: &context, at: p(-0.15, -0.30, o, s), size: s * 0.13, angle: -1.0, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.16, -0.34, o, s), size: s * 0.13, angle: 0.88, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.23, -0.56, o, s), size: s * 0.14, angle: -0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.08, -0.54, o, s), size: s * 0.13, angle: -0.40, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.13, -0.58, o, s), size: s * 0.14, angle: 0.68, color: ink, shape: .broad)
        case .mature:
            stem(in: &context, from: o, to: p(-0.02, -0.76, o, s), color: ink, width: 1.6)
            stem(in: &context, from: p(-0.01, -0.34, o, s), to: p(-0.24, -0.60, o, s), color: ink, width: 1.25)
            stem(in: &context, from: p(-0.01, -0.44, o, s), to: p(0.22, -0.66, o, s), color: ink, width: 1.25)
            leaf(in: &context, at: p(-0.16, -0.28, o, s), size: s * 0.13, angle: -1.05, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.16, -0.30, o, s), size: s * 0.13, angle: 0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.26, -0.58, o, s), size: s * 0.15, angle: -1.02, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.12, -0.60, o, s), size: s * 0.13, angle: -0.42, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.24, -0.62, o, s), size: s * 0.15, angle: 0.92, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.08, -0.64, o, s), size: s * 0.13, angle: 0.32, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.04, -0.76, o, s), size: s * 0.12, angle: -0.12, color: ink, shape: .broad)
        }
    }

    private static func drawNarrow(
        _ stage: GardenGrowthStage,
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        ink: Color
    ) {
        let o = origin
        let s = scale
        switch stage {
        case .seedling:
            stem(in: &context, from: o, to: p(0.00, -0.42, o, s), color: ink, width: 1.55, lean: 0.03)
            leaf(in: &context, at: p(0.04, -0.36, o, s), size: s * 0.21, angle: -1.28, color: ink, shape: .narrow)
        case .sprout:
            stem(in: &context, from: o, to: p(0.00, -0.52, o, s), color: ink, width: 1.3, lean: 0.03)
            leaf(in: &context, at: p(-0.04, -0.36, o, s), size: s * 0.18, angle: -2.05, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.05, -0.42, o, s), size: s * 0.18, angle: -1.15, color: ink, shape: .narrow)
        case .young:
            stem(in: &context, from: o, to: p(0.00, -0.64, o, s), color: ink, width: 1.35, lean: 0.02)
            leaf(in: &context, at: p(-0.07, -0.34, o, s), size: s * 0.18, angle: -2.15, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.07, -0.40, o, s), size: s * 0.18, angle: -1.05, color: ink, shape: .narrow)
            leaf(in: &context, at: p(-0.03, -0.54, o, s), size: s * 0.17, angle: -1.85, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.04, -0.60, o, s), size: s * 0.17, angle: -1.25, color: ink, shape: .narrow)
        case .growing:
            stem(in: &context, from: o, to: p(0.00, -0.74, o, s), color: ink, width: 1.4, lean: 0.02)
            stem(in: &context, from: p(0.00, -0.48, o, s), to: p(-0.08, -0.68, o, s), color: ink, width: 1.1, lean: 0.02)
            leaf(in: &context, at: p(-0.08, -0.32, o, s), size: s * 0.18, angle: -2.20, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.08, -0.38, o, s), size: s * 0.18, angle: -1.00, color: ink, shape: .narrow)
            leaf(in: &context, at: p(-0.10, -0.56, o, s), size: s * 0.17, angle: -2.05, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.06, -0.58, o, s), size: s * 0.17, angle: -1.15, color: ink, shape: .narrow)
            leaf(in: &context, at: p(-0.04, -0.70, o, s), size: s * 0.16, angle: -1.70, color: ink, shape: .narrow)
        case .mature:
            stem(in: &context, from: o, to: p(0.00, -0.80, o, s), color: ink, width: 1.45, lean: 0.02)
            stem(in: &context, from: p(0.00, -0.46, o, s), to: p(-0.10, -0.70, o, s), color: ink, width: 1.15, lean: 0.02)
            stem(in: &context, from: p(0.00, -0.52, o, s), to: p(0.10, -0.74, o, s), color: ink, width: 1.15, lean: 0.02)
            leaf(in: &context, at: p(-0.09, -0.30, o, s), size: s * 0.18, angle: -2.22, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.09, -0.34, o, s), size: s * 0.18, angle: -0.95, color: ink, shape: .narrow)
            leaf(in: &context, at: p(-0.12, -0.56, o, s), size: s * 0.17, angle: -2.10, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.12, -0.60, o, s), size: s * 0.17, angle: -1.05, color: ink, shape: .narrow)
            leaf(in: &context, at: p(-0.06, -0.72, o, s), size: s * 0.16, angle: -1.85, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.05, -0.76, o, s), size: s * 0.16, angle: -1.25, color: ink, shape: .narrow)
            leaf(in: &context, at: p(0.00, -0.82, o, s), size: s * 0.14, angle: -1.55, color: ink, shape: .narrow)
        }
    }

    private static func drawBranching(
        _ stage: GardenGrowthStage,
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        ink: Color
    ) {
        let o = origin
        let s = scale
        switch stage {
        case .seedling:
            stem(in: &context, from: o, to: p(-0.04, -0.36, o, s), color: ink, width: 1.6, lean: 0.12)
            leaf(in: &context, at: p(-0.10, -0.30, o, s), size: s * 0.14, angle: -0.68, color: ink, shape: .broad)
        case .sprout:
            stem(in: &context, from: o, to: p(-0.02, -0.36, o, s), color: ink, width: 1.35, lean: 0.10)
            stem(in: &context, from: p(-0.02, -0.28, o, s), to: p(-0.16, -0.44, o, s), color: ink, width: 1.15)
            stem(in: &context, from: p(-0.02, -0.28, o, s), to: p(0.14, -0.42, o, s), color: ink, width: 1.15)
            leaf(in: &context, at: p(-0.17, -0.44, o, s), size: s * 0.11, angle: -0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.16, -0.42, o, s), size: s * 0.11, angle: 0.85, color: ink, shape: .broad)
        case .young:
            stem(in: &context, from: o, to: p(-0.02, -0.48, o, s), color: ink, width: 1.4, lean: 0.08)
            stem(in: &context, from: p(-0.02, -0.26, o, s), to: p(-0.20, -0.48, o, s), color: ink, width: 1.2)
            stem(in: &context, from: p(-0.02, -0.30, o, s), to: p(0.18, -0.50, o, s), color: ink, width: 1.2)
            leaf(in: &context, at: p(-0.12, -0.28, o, s), size: s * 0.11, angle: -1.05, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.12, -0.30, o, s), size: s * 0.11, angle: 0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.22, -0.50, o, s), size: s * 0.12, angle: -0.95, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.20, -0.52, o, s), size: s * 0.12, angle: 0.85, color: ink, shape: .broad)
        case .growing:
            stem(in: &context, from: o, to: p(-0.02, -0.62, o, s), color: ink, width: 1.45, lean: 0.07)
            stem(in: &context, from: p(-0.02, -0.24, o, s), to: p(-0.22, -0.50, o, s), color: ink, width: 1.2)
            stem(in: &context, from: p(-0.02, -0.32, o, s), to: p(0.20, -0.54, o, s), color: ink, width: 1.2)
            stem(in: &context, from: p(-0.02, -0.46, o, s), to: p(-0.16, -0.66, o, s), color: ink, width: 1.1)
            leaf(in: &context, at: p(-0.14, -0.26, o, s), size: s * 0.11, angle: -1.1, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.13, -0.30, o, s), size: s * 0.11, angle: 1.0, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.24, -0.52, o, s), size: s * 0.13, angle: -0.98, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.22, -0.56, o, s), size: s * 0.13, angle: 0.88, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.18, -0.68, o, s), size: s * 0.12, angle: -0.70, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.06, -0.64, o, s), size: s * 0.11, angle: 0.25, color: ink, shape: .broad)
        case .mature:
            stem(in: &context, from: o, to: p(-0.02, -0.70, o, s), color: ink, width: 1.5, lean: 0.06)
            stem(in: &context, from: p(-0.02, -0.22, o, s), to: p(-0.24, -0.52, o, s), color: ink, width: 1.25)
            stem(in: &context, from: p(-0.02, -0.28, o, s), to: p(0.22, -0.54, o, s), color: ink, width: 1.25)
            stem(in: &context, from: p(-0.02, -0.46, o, s), to: p(-0.18, -0.72, o, s), color: ink, width: 1.15)
            stem(in: &context, from: p(-0.02, -0.50, o, s), to: p(0.16, -0.74, o, s), color: ink, width: 1.15)
            leaf(in: &context, at: p(-0.14, -0.24, o, s), size: s * 0.11, angle: -1.12, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.14, -0.28, o, s), size: s * 0.11, angle: 1.02, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.26, -0.54, o, s), size: s * 0.13, angle: -1.00, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.24, -0.56, o, s), size: s * 0.13, angle: 0.90, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.20, -0.72, o, s), size: s * 0.12, angle: -0.72, color: ink, shape: .broad)
            leaf(in: &context, at: p(0.18, -0.74, o, s), size: s * 0.12, angle: 0.68, color: ink, shape: .broad)
            leaf(in: &context, at: p(-0.02, -0.72, o, s), size: s * 0.11, angle: 0.08, color: ink, shape: .broad)
        }
    }

    private static func drawRounded(
        _ stage: GardenGrowthStage,
        in context: inout GraphicsContext,
        origin: CGPoint,
        scale: CGFloat,
        ink: Color
    ) {
        let o = origin
        let s = scale
        switch stage {
        case .seedling:
            stem(in: &context, from: o, to: p(0.02, -0.34, o, s), color: ink, width: 1.6)
            leaf(in: &context, at: p(0.07, -0.28, o, s), size: s * 0.17, angle: 0.38, color: ink, shape: .rounded, bias: 0.04)
        case .sprout:
            stem(in: &context, from: o, to: p(0.01, -0.42, o, s), color: ink, width: 1.4)
            leaf(in: &context, at: p(-0.12, -0.28, o, s), size: s * 0.155, angle: -0.72, color: ink, shape: .rounded, bias: -0.05)
            leaf(in: &context, at: p(0.13, -0.34, o, s), size: s * 0.145, angle: 0.42, color: ink, shape: .rounded, bias: 0.05)
        case .young:
            stem(in: &context, from: o, to: p(-0.01, -0.54, o, s), color: ink, width: 1.45)
            leaf(in: &context, at: p(-0.16, -0.30, o, s), size: s * 0.16, angle: -0.82, color: ink, shape: .rounded, bias: -0.05)
            leaf(in: &context, at: p(0.15, -0.28, o, s), size: s * 0.14, angle: 0.70, color: ink, shape: .rounded, bias: 0.04)
            leaf(in: &context, at: p(-0.06, -0.46, o, s), size: s * 0.155, angle: -0.28, color: ink, shape: .rounded, bias: 0.03)
            leaf(in: &context, at: p(0.12, -0.50, o, s), size: s * 0.145, angle: 0.32, color: ink, shape: .rounded, bias: -0.03)
        case .growing:
            stem(in: &context, from: o, to: p(-0.01, -0.62, o, s), color: ink, width: 1.5)
            stem(in: &context, from: p(0.00, -0.34, o, s), to: p(-0.18, -0.52, o, s), color: ink, width: 1.15)
            leaf(in: &context, at: p(-0.17, -0.26, o, s), size: s * 0.15, angle: -0.95, color: ink, shape: .rounded, bias: -0.04)
            leaf(in: &context, at: p(0.16, -0.32, o, s), size: s * 0.14, angle: 0.62, color: ink, shape: .rounded, bias: 0.05)
            leaf(in: &context, at: p(-0.20, -0.52, o, s), size: s * 0.165, angle: -0.48, color: ink, shape: .rounded, bias: -0.03)
            leaf(in: &context, at: p(0.14, -0.54, o, s), size: s * 0.15, angle: 0.28, color: ink, shape: .rounded, bias: 0.04)
            leaf(in: &context, at: p(-0.04, -0.60, o, s), size: s * 0.14, angle: -0.12, color: ink, shape: .rounded, bias: 0.02)
        case .mature:
            stem(in: &context, from: o, to: p(-0.01, -0.68, o, s), color: ink, width: 1.55)
            stem(in: &context, from: p(0.00, -0.32, o, s), to: p(-0.20, -0.54, o, s), color: ink, width: 1.2)
            stem(in: &context, from: p(-0.01, -0.38, o, s), to: p(0.18, -0.56, o, s), color: ink, width: 1.15)
            leaf(in: &context, at: p(-0.17, -0.24, o, s), size: s * 0.15, angle: -0.98, color: ink, shape: .rounded, bias: -0.05)
            leaf(in: &context, at: p(0.16, -0.30, o, s), size: s * 0.14, angle: 0.68, color: ink, shape: .rounded, bias: 0.04)
            leaf(in: &context, at: p(-0.22, -0.52, o, s), size: s * 0.17, angle: -0.55, color: ink, shape: .rounded, bias: -0.04)
            leaf(in: &context, at: p(0.20, -0.54, o, s), size: s * 0.155, angle: 0.38, color: ink, shape: .rounded, bias: 0.05)
            leaf(in: &context, at: p(-0.10, -0.62, o, s), size: s * 0.15, angle: -0.32, color: ink, shape: .rounded, bias: 0.03)
            leaf(in: &context, at: p(0.11, -0.64, o, s), size: s * 0.14, angle: 0.18, color: ink, shape: .rounded, bias: -0.03)
            leaf(in: &context, at: p(-0.02, -0.70, o, s), size: s * 0.13, angle: 0.04, color: ink, shape: .rounded, bias: 0.02)
        }
    }
}

struct BotanicalPlantView: View {
    let stage: GardenGrowthStage
    var variant: PlantVariant = .broadLeaf

    var body: some View {
        PlantView(variant: variant, stage: stage)
    }
}
