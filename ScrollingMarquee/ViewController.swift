//
//  ViewController.swift
//  ScrollingMarquee
//
//  Created by Michael A. Crawford on 6/8/16.
//  Copyright © 2016 Crawford Design Engineering, LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let sm = ScrollingMarquee(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: 44.0))
        sm.delegate = self
        sm.delay = 2.0
        sm.text = "This is a string that is too wide for the view I've assigned it to."
        sm.mode = /* .Circular */ .FullExit
        sm.scrollSpeed = .Fast
        self.view.addSubview(sm)
        sm.startScrolling()
    }
}


extension ViewController: ScrollingMarqueeDelegate {
    func scrollingMarquee(marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: NSTimeInterval) {
        if delay > 0 {
            print("Scrolling will start in \(delay) seconds")
        } else {
            print("Scrolling started")
        }
    }
    
    func scrollingMarquee(marquee: ScrollingMarquee, didEndScrolling finished: Bool) {
        print("Scrolling \(finished ? "finished" : "interrupted")")
    }
}
