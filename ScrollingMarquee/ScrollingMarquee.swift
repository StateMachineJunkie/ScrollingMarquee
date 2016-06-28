//
//  ScrollingMarquee.swift
//  ScrollingMarquee
//
//  Created by Michael A. Crawford on 6/8/16.
//  Copyright © 2016 Crawford Design Engineering, LLC. All rights reserved.
//

import UIKit

protocol ScrollingMarqueeDelegate {
    func scrollingMarquee(marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: NSTimeInterval)
    func scrollingMarquee(marquee: ScrollingMarquee, didEndScrolling finished: Bool)
}

class ScrollingMarquee: UIView {
    enum Mode {
        case BestFit
        case Circular
        case FullExit
    }
    
    enum Speed : CGFloat {
        case Slow = 40.0
        case Medium = 80.0
        case Fast = 160.0
    }
    
    // MARK: - Properties
    var automaticMode: Bool = false
    
    override var backgroundColor: UIColor?{
        get {
            return label.backgroundColor
        }
        set(value) {
            label.backgroundColor = value
        }
    }
    
    var delay: NSTimeInterval = 0
    
    var delegate: ScrollingMarqueeDelegate?
    
    var font: UIFont! {
        get { return label.font }
        set(value) { self.label.font = value }
    }
    
    private var label: UILabel
    
    var mode: Mode = .BestFit
    var scrollSpeed: Speed = .Slow  // points per second
    // TODO: Add didSet for immediate change on scrollSpeed assignment
    
    private(set) var scrollingEnabled: Bool = false
    private(set) var scrollInProgress: Bool = false
    
    private var scrollRequired: Bool {
        return frame.size.width < label.frame.size.width
    }
    
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
    
    func stopScrolling() {
        // On the next animation cycle, this will prevent us from restarting the scroll
        // animation.
        scrollingEnabled = false
    }
    
    // MARK: - Implementation Methods
    func restartScrolling() {
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
