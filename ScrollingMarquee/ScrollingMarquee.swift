//
//  ScrollingMarquee.swift
//  ScrollingMarquee
//
//  Created by Michael A. Crawford on 6/8/16.
//  Copyright © 2016 Crawford Design Engineering, LLC. All rights reserved.
//

import UIKit

/// Notification callbacks indicating basic state transitions of the `ScrollingMarquee`.
protocol ScrollingMarqueeDelegate {
    /// The scroll animation has been initiated. If the delay parameter of the
    /// animations has been configured, it will be passed in as the `delay`
    /// parameter of this notification callback.
    func scrollingMarquee(_ marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: TimeInterval)

    /// The scroll animation has ended either due to interruption or completion.
    /// The `finished` parameter indicates which.
    func scrollingMarquee(_ marquee: ScrollingMarquee, didEndScrolling finished: Bool)
}

@IBDesignable
class ScrollingMarquee: UIView {
    enum Error: Swift.Error {
        // The text to be displayed fits within the constrained label width.
        case scrollingNotRequired
    }

    /// ScrollingMarquee supports three types of subtly different behavior.
    /// `BestFit`, `Circular`, and `FullExit`. The behaviors are described below.
    enum Mode: Int {
        /// Display the text starting at the left extent of the control and
        /// scroll until the entire content of the string is visible on the
        /// right extent.
        case bestFit
        /// Scroll the text in from the right and continue scrolling until the
        /// entire length of the text scrolls out on the left.
        case circular
        /// Display the text starting at the left extent of the control and
        /// scroll until the entire length of the text has exited on the left.
        case fullExit
    }
    
    /// The scroll animation can be configured with one three arbitrarily chosen
    /// values. These values are in points per second (PPS) but we simply know
    /// them as `Slow`, `Medium`, and `Fast`. Each doubles the speed of the
    /// previous value, respectively.
    enum Speed: CGFloat {
        /// 40 PPS
        case slow = 40.0
        /// 80 PPS
        case medium = 80.0
        /// 160 PPS
        case fast = 160.0
    }
    
    // MARK: - Properties
    
    /// Indicates whether or not scrolling starts automatically when the value
    /// of the `text` property is changed.
    @IBInspectable var automaticMode: Bool = false

    @IBInspectable override var backgroundColor: UIColor? {
        get { return label.backgroundColor }
        set { label.backgroundColor = newValue }
    }
    
    /// Number of seconds to delay before actually scrolling animation begins.
    /// Fractional values are allowed.
    @IBInspectable var delay: TimeInterval = 0

    /// Delegate object that will be notified when the scrolling animation
    /// begins and ends.
    var delegate: ScrollingMarqueeDelegate?
    
    /// Font used to display the marquee. If not is specified, the default font
    /// is `system`.
    @IBInspectable var font: UIFont! {
        get { return label.font }
        set { self.label.font = newValue }
    }
    
    // Used for implementation
    private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Determines scrolling behavior. See `Mode` enum for details. Default value
    /// is `BestFit`.
    var mode: Mode = .bestFit

    @IBInspectable var modeAdapter: Int {
        get { mode.rawValue }
        set(modeIndex) { mode = Mode(rawValue: modeIndex) ?? .bestFit }
    }

    /// Determines scrolling speed. See `Speed` enum for details. Default value
    /// is `Slow`.
    var scrollSpeed: Speed = .slow  // points per second

    @IBInspectable var scrollSpeedAdapter: CGFloat {
        get { scrollSpeed.rawValue }
        set(scrollSpeedIndex) { scrollSpeed = Speed(rawValue: scrollSpeedIndex) ?? .slow }
    }

    // TODO: Add didSet for immediate change to animation on scrollSpeed assignment.
    
    /// Indicates whether or not scrolling is current turned on.
    private(set) var scrollingEnabled: Bool = false
    
    /// Indicates whether or not scrolling animation is in progress.
    private(set) var scrollInProgress: Bool = false
    
    /// Determine if scrolling is necessary given the current value of the `text`
    /// property.
    private var scrollRequired: Bool {
        return frame.size.width < label.frame.size.width
    }
    
    /// Text to be displayed in the marquee. If the displayed content of this
    /// value is not wider than the width of the marquee control, no scrolling
    /// will occur and attempts to start scrolling will have no effect.
    @IBInspectable var text: String? {
        get { return self.label.text }
        set {
            // re-calculate and resize label according to the width of the new text value
            guard let text = newValue else { return }

            let textSize = text.size(withAttributes: [NSAttributedString.Key.font : label.font!])
            var frame = CGRectZero
            frame.size = CGSize(width: textSize.width, height: textSize.height)
            label.frame = frame
            
            // set text value
            self.label.text = text
            
            if automaticMode {
                try? startScrolling()
            }
        }
    }
    
    /// Color of the text displayed in the marquee. The default value is the system's `UILabel` color, which adapts
    /// dynamically to Dark Mode changes. Setting this property to `nil` causes it to be reset to the default value.
    @IBInspectable var textColor: UIColor! {
        get { return self.label.textColor }
        set { self.label.textColor = newValue }
    }
    
    // MARK: - Initialization
    override convenience init(frame: CGRect) {
        self.init(frame: frame, font: nil, text: nil)
    }
    
    convenience init(frame: CGRect, text: String) {
        self.init(frame: frame, font: nil, text: text)
    }
    
    convenience init(frame: CGRect, font: UIFont) {
        self.init(frame: frame, font: font, text: nil)
    }
    
    init(frame: CGRect, font: UIFont?, text: String?) {
        super.init(frame: frame)

        let label = UILabel(frame: CGRectZero)

        if let font {
            label.font = font
        } else {
            label.font = UIFont.systemFont(ofSize: frame.size.height * 0.8)
        }

        // calculate width of text, if provided
        if let text {
            label.text = text
            label.frame = computeMarqueeFrame(for: label)
        }

        self.label = label
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // calculate width of text, if provided
        label.frame = computeMarqueeFrame(for: label)
        commonInit()
    }

    // MARK - UIView Overrides

    override var intrinsicContentSize: CGSize {
        label.intrinsicContentSize
    }

    override class var requiresConstraintBasedLayout: Bool { true }

    // MARK: - Public Methods
    
    /// Start the scrolling animation. This method will only have an effect if
    /// the `text` property has a valid string that is longer than the width of
    /// the control. If scrolling has already been turned on, this method does
    /// nothing.
    func startScrolling() throws {
        guard scrollRequired == true else { throw Error.scrollingNotRequired }

        // Scrolling has been requested. If a scroll animation is already in progress,
        // do not proceed but let it finish. If not, we may proceed by determining where
        // the animation must start, what speed it should run at, and where the animation
        // should end. All of these questions are affected by the animation mode.
        scrollingEnabled = true
        
        if !scrollInProgress {
            scrollInProgress = true
            
            // reset the origin of the label, just in case . . .
            if CGRectGetMinX(label.frame) != 0.0 {
                var frame = label.frame
                
                if .circular == mode {
                    frame.origin.x = self.bounds.size.width
                } else {
                    frame.origin.x = 0.0
                }
                
                label.frame = frame
            }
            
            // Calculate animation variables (we assume the clipping frame is smaller than
            // the label frame, if we get this far).
            var offset: CGFloat = 0
            
            if .bestFit == mode {
                // calculate offset for best-fit
                offset = ((label.bounds.size.width - self.bounds.size.width) + 10.0)
            } else if .circular == mode {
                // calculate offset for circular mode
                offset = label.bounds.size.width + 10.0
                
                if self.bounds.size.width == label.frame.origin.x {
                    offset += self.bounds.size.width
                }
            } else {
                // calculate offset for full-exit
                offset = label.bounds.size.width + 10.0
            }
            
            let duration = label.frame.size.width / scrollSpeed.rawValue
            var newLabelFrame = label.frame
            newLabelFrame.origin.x -= offset
            
            // perform animation
            UIView.animate(withDuration: TimeInterval(duration), delay: delay, options: .curveLinear, animations: {
                self.label.frame = newLabelFrame
                if let delegate = self.delegate {
                    DispatchQueue.main.async {
                        delegate.scrollingMarquee(self, didBeginScrollingWithDelay: self.delay)
                    }
                }
            }, completion: { finished in
                if let delegate = self.delegate {
                    DispatchQueue.main.async {
                        delegate.scrollingMarquee(self, didEndScrolling: finished)
                    }
                }
                // Our scroll animation has stopped either because it finished or
                // because UIKit stopped it prematurely (usually due to the view
                // disappearing). In either case we want to reflect the stopped state
                // and, if it makes sense, restart the scrolling animation.
                self.scrollInProgress = false
                
                if finished {
                    DispatchQueue.main.async {
                        try? self.restartScrolling()
                    }
                }
            })
        } else {
            // reset the origin of the label, just in case . . .
            var frame       = label.frame
            frame.origin    = CGPointZero
            label.frame     = frame
        }
    }
    
    /// Turn off scrolling for this control. When invoked, this method will prevent
    /// a currently executing scrolling animation from being automatically repeated.
    /// If there is an animation in progress, there is no apparent immediate effect
    /// to its invocation.
    func stopScrolling() {
        // On the next animation cycle, this will prevent us from restarting the scroll
        // animation.
        scrollingEnabled = false
    }
    
    // MARK: - Implementation Methods
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        // This view should match the height of the label it uses for implementation.
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: label.topAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])

        // default to transparent background with black text
        super.backgroundColor = .clear
        label.backgroundColor = .clear
        label.textColor = .black

        // make sure clipping is in effect
        self.clipsToBounds = true
    }

    private func computeMarqueeFrame(for label: UILabel) -> CGRect {
        guard let text = label.text else { return .zero }
        let textSize = text.size(withAttributes: [NSAttributedString.Key.font: label.font!])
        // allocate label and size it based on the height of frame and width of text
        return CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
    }

    private func restartScrolling() throws {
        // If scrolling is still enabled and is required by the length of the label,
        // restart the scrolling animation.
        if true == scrollingEnabled {
            try startScrolling()
        } else {
            // since we are not going to continue scrolling, reset the label to the
            // default position.
            if CGRectGetMinX(label.frame) != 0.0 {
                let origin = CGPoint(x: 0.0, y: label.frame.origin.y)
                label.frame = CGRect(origin: origin, size: label.frame.size)
                // TODO: Use position instead
            }
        }
    }
}
