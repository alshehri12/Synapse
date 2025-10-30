//
//  Animations.swift
//  Synapse Design System
//
//  Animation system with predefined curves and durations
//

import SwiftUI

// MARK: - Animation System
struct Animations {

    // MARK: - Duration
    struct Duration {
        static let instant: Double = 0.1
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.4
        static let slower: Double = 0.6
        static let slowest: Double = 0.8
    }

    // MARK: - Spring Animations
    struct Spring {
        let response: Double
        let dampingFraction: Double
        let blendDuration: Double

        // Predefined springs
        static let bouncy = Spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
        static let smooth = Spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
        static let snappy = Spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)
        static let gentle = Spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0)

        var animation: Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }

    // MARK: - Easing Curves
    static let easeIn = Animation.easeIn(duration: Duration.normal)
    static let easeOut = Animation.easeOut(duration: Duration.normal)
    static let easeInOut = Animation.easeInOut(duration: Duration.normal)
    static let linear = Animation.linear(duration: Duration.normal)

    // MARK: - Semantic Animations
    static let buttonTap = Spring.snappy.animation
    static let pageTransition = Spring.smooth.animation
    static let modal = Spring.smooth.animation
    static let toast = Spring.bouncy.animation
    static let cardHover = Animation.easeOut(duration: Duration.fast)
    static let loading = Animation.linear(duration: Duration.slow).repeatForever(autoreverses: false)
    static let pulse = Animation.easeInOut(duration: Duration.slow).repeatForever(autoreverses: true)
    static let shake = Animation.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)

    // MARK: - Preset Animations
    static func spring(
        response: Double = 0.6,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }

    static func easeInOut(duration: Double = Duration.normal) -> Animation {
        .easeInOut(duration: duration)
    }

    static func easeOut(duration: Double = Duration.normal) -> Animation {
        .easeOut(duration: duration)
    }

    static func linear(duration: Double = Duration.normal) -> Animation {
        .linear(duration: duration)
    }
}

// MARK: - View Extensions for Animations
extension View {

    // MARK: - Animated State Changes
    func animatedState<V: Equatable>(_ value: V) -> some View {
        self.animation(Animations.Spring.smooth.animation, value: value)
    }

    func smoothAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(Animations.Spring.smooth.animation, value: value)
    }

    func snappyAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(Animations.Spring.snappy.animation, value: value)
    }

    func bouncyAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(Animations.Spring.bouncy.animation, value: value)
    }

    // MARK: - Transition Modifiers
    func fadeTransition() -> some View {
        self.transition(.opacity.animation(Animations.easeInOut))
    }

    func scaleTransition() -> some View {
        self.transition(.scale.animation(Animations.Spring.bouncy.animation))
    }

    func slideTransition(edge: Edge = .bottom) -> some View {
        self.transition(.move(edge: edge).animation(Animations.Spring.smooth.animation))
    }

    // MARK: - Pulse Effect
    func pulseEffect(isActive: Bool = true) -> some View {
        self
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(Animations.pulse, value: isActive)
    }

    // MARK: - Shake Effect
    func shakeEffect(trigger: Int) -> some View {
        self.modifier(ShakeEffect(shakes: trigger))
    }
}

// MARK: - Shake Effect Modifier
struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(CGFloat(shakes) * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

// MARK: - Loading Animation Modifiers
extension View {

    // MARK: - Shimmer Effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    // MARK: - Rotate Effect (for loading spinners)
    func rotateForever(duration: Double = Animations.Duration.slow) -> some View {
        self.modifier(RotateForeverModifier(duration: duration))
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    Color.white.opacity(0.3),
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: phase * geometry.size.width)
                        .mask(content)
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Rotate Forever Modifier
struct RotateForeverModifier: ViewModifier {
    let duration: Double
    @State private var isRotating = 0.0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration).repeatForever(autoreverses: false)
                ) {
                    isRotating = 360
                }
            }
    }
}

// MARK: - Scale Button Effect
struct DSScaleButtonStyle: ButtonStyle {
    let pressedScale: CGFloat

    init(pressedScale: CGFloat = 0.95) {
        self.pressedScale = pressedScale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
    }
}

extension View {
    func scaleButtonStyle(pressedScale: CGFloat = 0.95) -> some View {
        self.buttonStyle(DSScaleButtonStyle(pressedScale: pressedScale))
    }
}
