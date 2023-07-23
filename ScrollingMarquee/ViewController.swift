//
//  ViewController.swift
//  ScrollingMarquee
//
//  Created by Michael A. Crawford on 6/8/16.
//  Copyright © 2016 Crawford Design Engineering, LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var sm: ScrollingMarquee!
    @IBOutlet weak var modeSelector: UISegmentedControl!
    @IBOutlet weak var speedSelector: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSMForUseFromIB()
    }

    // MARK: - Target Actions

    @IBAction func modeSelectionDidChange(_ sender: UISegmentedControl) {
        sm.mode = ScrollingMarquee.Mode(rawValue: modeSelector.selectedSegmentIndex)!
    }

    @IBAction func speedSelectionDidChange(_ sender: UISegmentedControl) {
        sm.scrollSpeed = speedFromSegmentIndex(speedSelector.selectedSegmentIndex)
    }

    #if false
    private func configureSM() {
        let sm = ScrollingMarquee(frame: CGRect(x: 0, y: 60, width: view.bounds.width, height: 44.0))
        sm.delegate = self
        sm.delay = 2.0
        sm.text = "This is a string that is too wide for the view I've assigned it to."
        sm.mode = /* .circular */ .fullExit
        sm.scrollSpeed = .fast
        self.view.addSubview(sm)
    }
    #endif

    private func configureSMForUseFromIB() {
        let mode = ScrollingMarquee.Mode(rawValue: modeSelector.selectedSegmentIndex) ?? .bestFit
        sm.mode = mode
        let speed = speedFromSegmentIndex(speedSelector.selectedSegmentIndex)
        sm.delegate = self
        try? sm.startScrolling()
    }

    // FIXME: We are missing a view-model here!
    private func speedFromSegmentIndex(_ segmentIndex: Int) -> ScrollingMarquee.Speed {
        switch segmentIndex {
        case 1: return .medium
        case 2: return .fast
        default: return .slow
        }
    }
}

extension ViewController: ScrollingMarqueeDelegate {
    func scrollingMarquee(_ marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: TimeInterval) {
        if delay > 0 {
            print("Scrolling will start in \(delay) seconds")
        } else {
            print("Scrolling started; speed \(marquee.scrollSpeed)")
        }
    }
    
    func scrollingMarquee(_ marquee: ScrollingMarquee, didEndScrolling finished: Bool) {
        print("Scrolling \(finished ? "finished" : "interrupted")")
    }
}
