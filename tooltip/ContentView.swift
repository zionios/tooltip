//
//  ContentView.swift
//  tooltip
//
//  Created by BaekHyeonEun on 2022/12/14.
//

import SwiftUI

struct ContentView: View {
    
    var tooltipConfig = DefaultTooltipConfig()
    
    init() {
        self.tooltipConfig.enableAnimation = true
        self.tooltipConfig.animationOffset = 100
        self.tooltipConfig.animationTime = 1
    }
    
    
    var body: some View {
        VStack {
            Image(systemName: "             ")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .tooltip(.center, config: tooltipConfig) {
                    Text("center")
                        .foregroundColor(.blue)
                }
                .tooltip(.bottom, config: tooltipConfig) {
                    Text("bottom")
                        .foregroundColor(.blue)
                }
                .tooltip(.bottomLeft) {
                    Text("bottomLeft")
                        .foregroundColor(.blue)
                }
                .tooltip(.bottomRight) {
                    Text("bottomRight")
                        .foregroundColor(.blue)
                }
                .tooltip(.left) {
                    Text("left")
                        .foregroundColor(.blue)
                }
                .tooltip(.right) {
                    Text("right")
                        .foregroundColor(.blue)
                }
                .tooltip(.top) {
                    Text("top")
                        .foregroundColor(.blue)
                }
                .tooltip(.topLeft) {
                    Text("topLeft")
                        .foregroundColor(.blue)
                }
                .tooltip(.topRight) {
                    Text("topRight")
                        .foregroundColor(.blue)
                }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


public struct ArrowShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines([
            CGPoint(x: 0, y: rect.height),
            CGPoint(x: rect.width / 2, y: 0),
            CGPoint(x: rect.width, y: rect.height),
        ])
        return path
    }
}

struct ArrowShape_Preview: PreviewProvider {
    static var previews: some View {
        ArrowShape().stroke()
    }
}

struct TooltipModifier<TooltipContent: View>: ViewModifier {
    // MARK: - Uninitialised properties
    var enabled: Bool
    var config: TooltipConfig
    var content: TooltipContent


    // MARK: - Initialisers
    init(enabled: Bool, config: TooltipConfig, @ViewBuilder content: @escaping () -> TooltipContent) {
        self.enabled = enabled
        self.config = config
        self.content = content()
    }

    // MARK: - Local state

    @State private var contentWidth: CGFloat = 10
    @State private var contentHeight: CGFloat = 10
    
    @State var animationOffset: CGFloat = 0
    @State var animation: Optional<Animation> = nil

    // MARK: - Computed properties

    var showArrow: Bool { config.showArrow && config.side.shouldShowArrow() }
    var actualArrowHeight: CGFloat { self.showArrow ? config.arrowHeight : 0 }

    var arrowOffsetX: CGFloat {
        switch config.side {
        case .bottom, .center, .top:
            return 0
        case .left:
            return (contentWidth / 2 + config.arrowHeight / 2)
        case .topLeft, .bottomLeft:
            return (contentWidth / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        case .right:
            return -(contentWidth / 2 + config.arrowHeight / 2)
        case .topRight, .bottomRight:
            return -(contentWidth / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        }
    }

    var arrowOffsetY: CGFloat {
        switch config.side {
        case .left, .center, .right:
            return 0
        case .top:
            return (contentHeight / 2 + config.arrowHeight / 2)
        case .topRight, .topLeft:
            return (contentHeight / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        case .bottom:
            return -(contentHeight / 2 + config.arrowHeight / 2)
        case .bottomLeft, .bottomRight:
            return -(contentHeight / 2
                + config.arrowHeight / 2
                - config.borderRadius / 2
                - config.borderWidth / 2)
        }
    }

    // MARK: - Helper functions

    private func offsetHorizontal(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .left, .topLeft, .bottomLeft:
            return -(contentWidth + config.margin + actualArrowHeight + animationOffset)
        case .right, .topRight, .bottomRight:
            return g.size.width + config.margin + actualArrowHeight + animationOffset
        case .top, .center, .bottom:
            return (g.size.width - contentWidth) / 2
        }
    }

    private func offsetVertical(_ g: GeometryProxy) -> CGFloat {
        switch config.side {
        case .top, .topRight, .topLeft:
            return -(contentHeight + config.margin + actualArrowHeight + animationOffset)
        case .bottom, .bottomLeft, .bottomRight:
            return g.size.height + config.margin + actualArrowHeight + animationOffset
        case .left, .center, .right:
            return (g.size.height - contentHeight) / 2
        }
    }
    
    // MARK: - Animation stuff
    
    private func dispatchAnimation() {
        if (config.enableAnimation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + config.animationTime) {
                self.animationOffset = config.animationOffset
                self.animation = config.animation
                DispatchQueue.main.asyncAfter(deadline: .now() + config.animationTime*0.1) {
                    self.animationOffset = 0
                    
                    self.dispatchAnimation()
                }
            }
        }
    }

    // MARK: - TooltipModifier Body Properties

    private var sizeMeasurer: some View {
        GeometryReader { g in
            Text("")
                .onAppear {
                    self.contentWidth = config.width ?? g.size.width
                    self.contentHeight = config.height ?? g.size.height
                }
        }
    }

    private var arrowView: some View {
        guard let arrowAngle = config.side.getArrowAngleRadians() else {
            return AnyView(EmptyView())
        }
        
        return AnyView(ArrowShape()
            .rotation(Angle(radians: arrowAngle))
            .stroke(config.borderColor)
            .background(ArrowShape()
                .offset(x: 0, y: 1)
                .rotation(Angle(radians: arrowAngle))
                .frame(width: config.arrowWidth+2, height: config.arrowHeight+1)
                .foregroundColor(config.backgroundColor)
                
            ).frame(width: config.arrowWidth, height: config.arrowHeight)
            .offset(x: self.arrowOffsetX, y: self.arrowOffsetY))
    }

    private var arrowCutoutMask: some View {
        guard let arrowAngle = config.side.getArrowAngleRadians() else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack {
                Rectangle()
                    .frame(
                        width: self.contentWidth + config.borderWidth * 2,
                        height: self.contentHeight + config.borderWidth * 2)
                    .foregroundColor(.white)
                Rectangle()
                    .frame(
                        width: config.arrowWidth,
                        height: config.arrowHeight + config.borderWidth)
                    .rotationEffect(Angle(radians: arrowAngle))
                    .offset(
                        x: self.arrowOffsetX,
                        y: self.arrowOffsetY)
                    .foregroundColor(.black)
            }
            .compositingGroup()
            .luminanceToAlpha()
        )
    }

    var tooltipBody: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius: config.borderRadius)
                    .stroke(config.borderWidth == 0 ? Color.clear : config.borderColor)
                    .frame(
                        minWidth: contentWidth,
                        idealWidth: contentWidth,
                        maxWidth: config.width,
                        minHeight: contentHeight,
                        idealHeight: contentHeight,
                        maxHeight: config.height
                    )
                    .background(
                        RoundedRectangle(cornerRadius: config.borderRadius)
                            .foregroundColor(config.backgroundColor)
                    )
                    .mask(self.arrowCutoutMask)
                
                ZStack {
                    content
                        .padding(config.contentPaddingEdgeInsets)
                        .frame(
                            width: config.width,
                            height: config.height
                        )
                        .fixedSize(horizontal: config.width == nil, vertical: true)
                }
                .background(self.sizeMeasurer)
                .overlay(self.arrowView)
            }
            .offset(x: self.offsetHorizontal(g), y: self.offsetVertical(g))
            .animation(self.animation)
            .zIndex(config.zIndex)
            .onAppear {
                self.dispatchAnimation()
            }
        }
    }

    // MARK: - ViewModifier properties

    func body(content: Content) -> some View {
        content
            .overlay(enabled ? tooltipBody.transition(config.transition) : nil)
    }
}

struct Tooltip_Previews: PreviewProvider {
    static var previews: some View {
        var config = DefaultTooltipConfig(side: .top)
        config.enableAnimation = true
        config.backgroundColor = Color(red: 0.8, green: 0.9, blue: 1)
        config.animationOffset = 129
        config.animationTime = 0.2
        config.width = 120
        config.height = 80
        
        
        return VStack {
            Text("Say...").tooltip(config: config) {
                Text("Something nice!")
            }
        }.previewDevice(.init(stringLiteral: "iPhone 12 mini"))
    }
}

// MARK: - with `enabled: Bool`
public extension View {
    // Only enable parameter accessible
    func tooltip<TooltipContent: View>(
        _ enabled: Bool = true,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        let config: TooltipConfig = DefaultTooltipConfig.shared

        return modifier(TooltipModifier(enabled: enabled, config: config, content: content))
    }

    // Only enable and config available
    func tooltip<TooltipContent: View>(
        _ enabled: Bool = true,
        config: TooltipConfig,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        modifier(TooltipModifier(enabled: enabled, config: config, content: content))
    }

    // Enable and side are available
    func tooltip<TooltipContent: View>(
        _ enabled: Bool = true,
        side: TooltipSide,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        var config = DefaultTooltipConfig.shared
        config.side = side

        return modifier(TooltipModifier(enabled: enabled, config: config, content: content))
    }
    
    // Enable, side and config parameters available
    func tooltip<TooltipContent: View>(
        _ enabled: Bool = true,
        side: TooltipSide,
        config: TooltipConfig,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        var config = config
        config.side = side

        return modifier(TooltipModifier(enabled: enabled, config: config, content: content))
    }
}

// MARK: - Without `enabled: Bool`
public extension View {
    // No-parameter tooltip
    func tooltip<TooltipContent: View>(
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        let config = DefaultTooltipConfig.shared
        
        return modifier(TooltipModifier(enabled: true, config: config, content: content))
    }
    
    // Only side configurable
    func tooltip<TooltipContent: View>(
        _ side: TooltipSide,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        var config = DefaultTooltipConfig.shared
        config.side = side

        return modifier(TooltipModifier(enabled: true, config: config, content: content))
    }

    // Side and config are configurable
    func tooltip<TooltipContent: View>(
        _ side: TooltipSide,
        config: TooltipConfig,
        @ViewBuilder content: @escaping () -> TooltipContent
    ) -> some View {
        var config = config
        config.side = side

        return modifier(TooltipModifier(enabled: true, config: config, content: content))
    }
}

public enum TooltipSide: Int {
    case center = -1
    
    case left = 2
    case right = 6
    case top = 4
    case bottom = 0

    case topLeft = 3
    case topRight = 5
    case bottomLeft = 1
    case bottomRight = 7
    
    func getArrowAngleRadians() -> Optional<Double> {
        if self == .center { return nil }
        return Double(self.rawValue) * .pi / 4
    }
    
    func shouldShowArrow() -> Bool {
        if self == .center { return false }
        return true
    }
}

public struct ArrowOnlyTooltipConfig: TooltipConfig {
    static var shared = ArrowOnlyTooltipConfig()

    public var side: TooltipSide = .bottom
    public var margin: CGFloat = 8
    public var zIndex: Double = 10000
        
    public var width: CGFloat?
    public var height: CGFloat?

    public var borderRadius: CGFloat = 8
    public var borderWidth: CGFloat = 0
    public var borderColor: Color = Color.primary
    public var backgroundColor: Color = Color.clear

    public var contentPaddingLeft: CGFloat = 8
    public var contentPaddingRight: CGFloat = 8
    public var contentPaddingTop: CGFloat = 4
    public var contentPaddingBottom: CGFloat = 4

    public var contentPaddingEdgeInsets: EdgeInsets {
        EdgeInsets(
            top: contentPaddingTop,
            leading: contentPaddingLeft,
            bottom: contentPaddingBottom,
            trailing: contentPaddingRight
        )
    }

    public var showArrow: Bool = true
    public var arrowWidth: CGFloat = 12
    public var arrowHeight: CGFloat = 6
    
    public var enableAnimation: Bool = false
    public var animationOffset: CGFloat = 10
    public var animationTime: Double = 1
    public var animation: Optional<Animation> = .easeInOut

    public var transition: AnyTransition = .opacity

    public init() {}

    public init(side: TooltipSide) {
        self.side = side
    }
}

public struct DefaultTooltipConfig: TooltipConfig {
    static var shared = DefaultTooltipConfig()

    public var side: TooltipSide = .bottom
    public var margin: CGFloat = 8
    public var zIndex: Double = 10000
    
    public var width: CGFloat?
    public var height: CGFloat?

    public var borderRadius: CGFloat = 8
    public var borderWidth: CGFloat = 2
    public var borderColor: Color = Color.primary
    public var backgroundColor: Color = Color.clear

    public var contentPaddingLeft: CGFloat = 8
    public var contentPaddingRight: CGFloat = 8
    public var contentPaddingTop: CGFloat = 4
    public var contentPaddingBottom: CGFloat = 4

    public var contentPaddingEdgeInsets: EdgeInsets {
        EdgeInsets(
            top: contentPaddingTop,
            leading: contentPaddingLeft,
            bottom: contentPaddingBottom,
            trailing: contentPaddingRight
        )
    }

    public var showArrow: Bool = true
    public var arrowWidth: CGFloat = 12
    public var arrowHeight: CGFloat = 30
    
    public var enableAnimation: Bool = false
    public var animationOffset: CGFloat = 10
    public var animationTime: Double = 1
    public var animation: Optional<Animation> = .easeInOut

    public var transition: AnyTransition = .opacity

    public init() {}

    public init(side: TooltipSide) {
        self.side = side
    }
}

public protocol TooltipConfig {
    // MARK: - Alignment

    var side: TooltipSide { get set }
    var margin: CGFloat { get set }
    var zIndex: Double { get set }
    
    // MARK: - Sizes
    var width: CGFloat? { get set }
    var height: CGFloat? { get set }

    // MARK: - Tooltip container

    var borderRadius: CGFloat { get set }
    var borderWidth: CGFloat { get set }
    var borderColor: Color { get set }
    var backgroundColor: Color { get set }

    // MARK: - Margins and paddings

    var contentPaddingLeft: CGFloat { get set }
    var contentPaddingRight: CGFloat { get set }
    var contentPaddingTop: CGFloat { get set }
    var contentPaddingBottom: CGFloat { get set }

    var contentPaddingEdgeInsets: EdgeInsets { get }

    // MARK: - Tooltip arrow

    var showArrow: Bool { get set }
    var arrowWidth: CGFloat { get set }
    var arrowHeight: CGFloat { get set }
    
    // MARK: - Animation settings
    var enableAnimation: Bool { get set }
    var animationOffset: CGFloat { get set }
    var animationTime: Double { get set }
    var animation: Optional<Animation> { get set }

    var transition: AnyTransition { get set }
}
