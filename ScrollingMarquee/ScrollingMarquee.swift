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
    /// parameter of this notificaiton callback.
    func scrollingMarquee(marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: NSTimeInterval)
    
    /// The scroll animation has ended either due to interruption or completion.
    /// The `finished` parameter indicates which.
    func scrollingMarquee(marquee: ScrollingMarquee, didEndScrolling finished: Bool)
}

class ScrollingMarquee: UIView {
    /// ScrollingMarquee supports three types of subtly different behavior.
    /// `BestFit`, `Circular`, and `FullExit`. The behaviors are described below.
    enum Mode {
        /// Display the text starting at the left extent of the control and
        /// scroll until the entire content of the string is visible on the
        /// right extent.
        case BestFit
        /// Scroll the text in from the right and continue scrolling intil the
        /// entire length of the text scrolls out on the left.
        case Circular
        /// Display the text starting at the left extent of the control and
        /// scroll until the entire length of the text has exited on the left.
        case FullExit
    }
    
    /// The scroll animation can be configured with one three arbitrarily chosen
    /// values. These values are in points per second (PPS) but we simply know
    /// them as `Slow`, `Medium`, and `Fast`. Each doubles the speed of the
    /// previous value, respectively.
    enum Speed : CGFloat {
        /// 40 PPS
        case Slow = 40.0
        /// 80 PPS
        case Medium = 80.0
        /// 160 PPS
        case Fast = 160.0
    }
    
    // MARK: - Properties
    
    /// Indicates whether or not scrolling starts automatically when the value
    /// of the `text` property is changed.
    var automaticMode: Bool = false
    
    override var backgroundColor: UIColor?{
        get {
            return label.backgroundColor
        }
        set(value) {
            label.backgroundColor = value
        }
    }
    
    /// Number of seconds to delay before actually scrolling animation begins.
    /// Fractional values are allowed.
    var delay: NSTimeInterval = 0
    
    /// Delegate object that will be notified when the scrolling animation
    /// begins and ends.
    var delegate: ScrollingMarqueeDelegate?
    
    /// Font used to display the marquee. If not is specified, the default font
    /// is `system`.
    var font: UIFont! {
        get { return label.font }
        set(value) { self.label.font = value }
    }
    
    // Used for implementation
    private var label: UILabel
    
    /// Determines scrolling behavior. See `Mode` enum for details. Defualt value
    /// is `BestFit`.
    var mode: Mode = .BestFit
    
    /// Determines scrolling speed. See `Speed` enum for details. Default value
    /// is `Slow`.
    var scrollSpeed: Speed = .Slow  // points per second
    
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
    /// value is not wider than the width of the marquee controll, no scrolling
    /// will occurr and attempts to start scrolling will have no effect.
    var text: String? {
        get { return self.label.text }
        set(value) {
            // re-calculate and resize label according ot the width of the new text value
            guard let text = value else { return }
            
            let textSize = text.sizeWithAttributes([NSFontAttributeName: label.font])
            var frame = CGRectZero
            frame.size = CGSize(width: textSize.width, height: textSize.height)
            label.frame = frame
            
            // set text value
            self.label.text = text
            
            if automaticMode {
                startScrolling()
            }
        }
    }
    
    /// Color of the text displayed in the marquee. The default value is black.
    var textColor: UIColor! {
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
        precondition(frame.size.width > 0 && frame.size.height > 0,
                     "The initial frame must not have zero width or height!")
        
        let label = UILabel(frame: CGRectZero)
        
        if let font = font {
            label.font = font
        } else {
            label.font = UIFont.systemFontOfSize(frame.size.height * 0.8)
        }
        
        // calculate width of text, if provided
        if let text = text {
            label.text = text
            let textSize = text.sizeWithAttributes([NSFontAttributeName: label.font])
            // allocate label and size it based on the height of frame and width of text
            let textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
            label.frame = textFrame
        }
        
        self.label = label
        super.init(frame: frame)
        self.addSubview(label)
        
        // default to transparent background with black text
        super.backgroundColor = UIColor.clearColor()
        label.backgroundColor = UIColor.clearColor()
        label.textColor = UIColor.blackColor()
        
        // make sure clipping is in effect
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    /// Start the scrolling animation. This method will only have an effect if
    /// the `text` property has a valid string that is longer than the width of
    /// the control. If scrolling has already been turned on, this method does
    /// nothing.
    func startScrolling() {
        guard scrollRequired == true else { return }
        
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
                
                if .Circular == mode {
                    frame.origin.x = self.bounds.size.width
                } else {
                    frame.origin.x = 0.0
                }
                
                label.frame = frame
            }
            
            // Calculate animation variables (we assume the clipping frame is smaller than
            // the label frame, if we get this far).
            var offset: CGFloat = 0
            
            if .BestFit == mode {
                // calculate offset for best-fit
                offset = ((label.bounds.size.width - self.bounds.size.width) + 10.0)
            } else if .Circular == mode {
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
            UIView.animateWithDuration(NSTimeInterval(duration), delay: delay, options: .CurveLinear, animations: {
                self.label.frame = newLabelFrame
                if let delegate = self.delegate {
                    dispatch_async(dispatch_get_main_queue(), {
                        delegate.scrollingMarquee(self, didBeginScrollingWithDelay: self.delay)
                    })
                }
            }, completion: { finished in
                if let delegate = self.delegate {
                    dispatch_async(dispatch_get_main_queue(), {
                        delegate.scrollingMarquee(self, didEndScrolling: finished)
                    })
                }
                // Our scroll animation has stopped either because it finished or
                // becaue UIKit stopped it prematurely (usually due to the view
                // disappearing). In either case we want to reflect the stopped state
                // and, if it makes sense, restart the scrolling animation.
                self.scrollInProgress = false
                
                if finished {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.restartScrolling()
                    })
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
    /// If there is an animation in progress, there is no apparent imediate effect
    /// to its invocation.
    func stopScrolling() {
        // On the next animation cycle, this will prevent us from restarting the scroll
        // animation.
        scrollingEnabled = false
    }
    
    // MARK: - Implementation Methods
    private func restartScrolling() {
        // If scrolling is still enabled and is required by the length of the label,
        // restart the scrolling animation.
        if true == scrollingEnabled {
            startScrolling()
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
