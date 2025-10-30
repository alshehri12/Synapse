# Synapse Design System

A comprehensive design system for the Synapse iOS app, providing consistent typography, spacing, colors, shadows, and animations.

## Overview

The Synapse Design System provides a unified set of design tokens and components to ensure consistency across the app. All design decisions are centralized here for easy maintenance and updates.

## Components

### 1. Typography (`Typography.swift`)

Defines all text styles and font scales used throughout the app.

#### Font Sizes Scale
- `xs`: 10pt - Extra small text
- `sm`: 12pt - Small text
- `base`: 14pt - Base body text
- `md`: 16pt - Medium text
- `lg`: 18pt - Large text
- `xl`: 20pt - Extra large
- `xl2-xl6`: 24pt-48pt - Display sizes

#### Semantic Text Styles
```swift
// Display
Text("Hello").displayLarge()
Text("Hello").displayMedium()
Text("Hello").displaySmall()

// Headings
Text("Hello").heading1()
Text("Hello").heading2()
Text("Hello").heading3()

// Body
Text("Hello").bodyLarge()
Text("Hello").bodyMedium()
Text("Hello").bodyBase()
Text("Hello").bodySmall()

// Labels
Text("Hello").labelLarge()
Text("Hello").labelMedium()
Text("Hello").labelSmall()

// Captions
Text("Hello").caption()
Text("Hello").captionBold()
Text("Hello").overline()
```

### 2. Spacing (`Spacing.swift`)

Provides consistent spacing values based on a 4pt grid system.

#### Spacing Scale
- `xs`: 4pt
- `sm`: 8pt
- `md`: 12pt
- `lg`: 16pt
- `xl`: 20pt
- `xl2`: 24pt
- `xl3`: 32pt
- `xl4`: 40pt
- `xl5`: 48pt
- `xl6`: 64pt

#### Usage Examples
```swift
// Padding shortcuts
VStack {
    Text("Hello")
}.paddingLG()  // 16pt padding

VStack {
    Text("Hello")
}.screenPadding()  // Screen-level padding

VStack {
    Text("Hello")
}.cardPadding()  // Card-level padding (16pt)

// Corner radius
RoundedRectangle()
    .cornerRadiusMedium()  // 12pt radius
```

#### Component Sizes
- Button heights: 36pt (small), 44pt (medium), 52pt (large)
- Input heights: 36pt (small), 44pt (medium), 52pt (large)
- Icons: 16pt (small), 20pt (medium), 24pt (large), 32pt (XL)
- Avatars: 32pt, 40pt, 56pt, 80pt
- Corner radius: 8pt, 12pt, 16pt, 24pt

### 3. Colors (`ColorTokens.swift`)

Comprehensive color system with light/dark mode support.

#### Brand Colors
```swift
Color.Brand.primary        // Primary green
Color.Brand.secondary      // Orange
Color.Brand.tertiary       // Blue
Color.Brand.primaryLight   // Light green
Color.Brand.primaryDark    // Dark green
```

#### Text Colors
```swift
Color.Text.primary         // Main text
Color.Text.secondary       // Secondary text
Color.Text.tertiary        // Tertiary text
Color.Text.disabled        // Disabled text
Color.Text.inverse         // Inverse text (on dark backgrounds)
Color.Text.link            // Link text
```

#### Background Colors
```swift
Color.Background.primary      // Main background
Color.Background.secondary    // Secondary background
Color.Background.tertiary     // Tertiary background
Color.Background.elevated     // Elevated surfaces
Color.Background.overlay      // Modal overlay
```

#### Border Colors
```swift
Color.Border.primary       // Default borders
Color.Border.secondary     // Secondary borders
Color.Border.focus         // Focus state
Color.Border.error         // Error state
```

#### Status Colors
```swift
Color.Status.success          // Success green
Color.Status.warning          // Warning orange
Color.Status.error            // Error red
Color.Status.info             // Info blue
Color.Status.successBackground // Light success bg
Color.Status.warningBackground // Light warning bg
Color.Status.errorBackground   // Light error bg
Color.Status.infoBackground    // Light info bg
```

#### Interactive States
```swift
Color.Interactive.enabled         // Enabled state
Color.Interactive.hover           // Hover state
Color.Interactive.pressed         // Pressed state
Color.Interactive.disabled        // Disabled state
Color.Interactive.disabledText    // Disabled text
```

#### Gradients
```swift
Color.Gradients.primary           // Primary gradient
Color.Gradients.secondary         // Secondary gradient
Color.Gradients.success           // Success gradient
Color.Gradients.authBackground    // Auth screen background
Color.Gradients.card              // Card gradient
```

#### Legacy Support
For backwards compatibility, original color names are mapped:
```swift
Color.accentGreen       -> Color.Brand.primary
Color.textPrimary       -> Color.Text.primary
Color.backgroundPrimary -> Color.Background.primary
// etc.
```

### 4. Shadows (`Shadows.swift`)

Elevation system for depth and hierarchy.

#### Shadow Levels
```swift
// Size-based
view.shadowXS()    // Minimal elevation
view.shadowSM()    // Small elevation
view.shadowMD()    // Medium elevation
view.shadowLG()    // Large elevation
view.shadowXL()    // Extra large elevation
view.shadowXL2()   // 2XL elevation
view.shadowXL3()   // 3XL elevation

// Semantic
view.cardShadow()      // For cards
view.cardHoverShadow() // For card hover state
view.buttonShadow()    // For buttons
view.modalShadow()     // For modals
view.dropdownShadow()  // For dropdowns
view.tooltipShadow()   // For tooltips

// Layered shadows for more depth
view.layeredCardShadow()
view.layeredModalShadow()
```

### 5. Animations (`Animations.swift`)

Predefined animation curves and durations.

#### Durations
```swift
Animations.Duration.instant   // 0.1s
Animations.Duration.fast      // 0.2s
Animations.Duration.normal    // 0.3s
Animations.Duration.slow      // 0.4s
Animations.Duration.slower    // 0.6s
Animations.Duration.slowest   // 0.8s
```

#### Spring Animations
```swift
Animations.Spring.bouncy      // Bouncy spring
Animations.Spring.smooth      // Smooth spring
Animations.Spring.snappy      // Snappy spring
Animations.Spring.gentle      // Gentle spring
```

#### Semantic Animations
```swift
Animations.buttonTap       // For button interactions
Animations.pageTransition  // For page changes
Animations.modal           // For modals
Animations.toast           // For toast messages
Animations.cardHover       // For card hover
Animations.loading         // For loading states
Animations.pulse           // For pulse effect
Animations.shake           // For shake effect
```

#### Animation Modifiers
```swift
// State-based animations
Text("Hello")
    .smoothAnimation(isVisible)
    .snappyAnimation(isSelected)
    .bouncyAnimation(count)

// Transitions
Text("Hello")
    .fadeTransition()
    .scaleTransition()
    .slideTransition(edge: .bottom)

// Effects
Circle()
    .pulseEffect(isActive: true)
    .shimmer(isActive: true)

ProgressView()
    .rotateForever()

// Shake effect
TextField("Email", text: $email)
    .shakeEffect(trigger: shakeCount)

// Button scale effect
Button("Tap me") { }
    .scaleButtonStyle(pressedScale: 0.95)
```

## Migration Guide

### From Old Code to Design System

#### Typography
```swift
// Before
Text("Hello")
    .font(.system(size: 24, weight: .bold))
    .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.20))

// After
Text("Hello")
    .heading3()
```

#### Spacing
```swift
// Before
VStack(spacing: 12) {
    Text("Hello")
}.padding(16)

// After
VStack(spacing: Spacing.md) {
    Text("Hello")
}.paddingLG()
```

#### Colors
```swift
// Before
Color(red: 0.24, green: 0.60, blue: 0.44)

// After
Color.Brand.primary
// or legacy name
Color.accentGreen
```

#### Shadows
```swift
// Before
.shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

// After
.shadowSM()
// or
.cardShadow()
```

#### Animations
```swift
// Before
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)

// After
.smoothAnimation(isVisible)
```

## Best Practices

1. **Always use design tokens** instead of hardcoded values
2. **Use semantic names** when possible (e.g., `cardShadow()` instead of `shadowSM()`)
3. **Be consistent** - use the same spacing, colors, and animations throughout
4. **Follow the 4pt grid system** for all spacing values
5. **Use appropriate text styles** for hierarchy
6. **Leverage dark mode colors** - they adapt automatically
7. **Test accessibility** - ensure proper contrast ratios

## Dark Mode Support

All colors in the design system support both light and dark modes automatically. When you use `Color.Brand.primary`, it will automatically switch between the light and dark variants based on the system appearance.

To test dark mode:
1. Remove `preferredColorScheme(.light)` from ContentView
2. Toggle dark mode in simulator/device settings
3. All design system colors will adapt automatically

## Future Enhancements

- [ ] Add breakpoint system for responsive design
- [ ] Add more gradient presets
- [ ] Add icon size system
- [ ] Add illustration style guide
- [ ] Add accessibility helpers (contrast checkers)
- [ ] Add component-specific tokens
- [ ] Add animation documentation with examples

## Support

For questions or improvements to the design system, please refer to this documentation or consult the development team.
