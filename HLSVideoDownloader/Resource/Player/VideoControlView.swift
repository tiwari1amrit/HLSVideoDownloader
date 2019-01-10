//
//  VideoControlView.swift
//  ATVideoPlayer
//
//  Created by Amrit Tiwari on 4/20/18.
//  Copyright © 2018 tiwariammit@gmail.com. All rights reserved.
//

import UIKit

@objc class VideoControlView: UIView {
    
    //    @IBOutlet weak var videoControlView: UIView!
    @IBOutlet weak var lblCurrentTime: UILabel!
    @IBOutlet weak var movieSlider: ATPlayerSlider!
    @IBOutlet weak var lblTotalTime: UILabel!
    @IBOutlet weak var btnToggleScreen: UIButton!
    
    @IBOutlet weak var btnHDAndSDView: UIControl!
    @IBOutlet weak var btnHDAndSD: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!    
    @IBOutlet weak var videoControlViewWidthConstraint: NSLayoutConstraint!
    
    fileprivate var sliderTapGuesture = UITapGestureRecognizer()
    
    @objc public var imageFullScreen = UIImage(named: "fullScreen")
    @objc public var imageFullScreenExit = UIImage(named: "fullScreenExit")
    
    @objc public var btnHDAndSDTrigger : ((Bool)->())?

    @objc public var sliderValueChanged : ((ATPlayerSlider, UITouch.Phase)->())?
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        //self.movieSlider?.addTarget(self, action: #selector(self.playbackSliderValueChanged(_:)), for: .valueChanged)
        
        self.movieSlider?.addTarget(self, action: #selector(self.onSliderValueChanged(_:withEvent:)), for: .valueChanged)

        //addTarget(self, action: #selector(self.test(_:)), for: [.touchUpInside , .touchUpOutside])

        
        self.sliderTapGuesture.numberOfTapsRequired = 1
        self.sliderTapGuesture.addTarget(self, action: #selector(self.playbackSliderTouched(sender:)))
        self.movieSlider?.addGestureRecognizer(self.sliderTapGuesture)
        self.sliderTapGuesture.cancelsTouchesInView = false
        self.btnToggleScreen.isSelected = false
        self.btnHDAndSD.isSelected = false
        self.btnHDAndSD.setTitle("HD", for: .normal)
        self.btnHDAndSD.layer.borderColor = UIColor.white.cgColor
        self.btnHDAndSD.layer.borderWidth = 1.0
        self.btnToggleScreen.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)//.imageView?.contentMode = .scaleAspectFit

    }
 

    
    @objc public class func loadFromNib() -> VideoControlView{
        
        return (Bundle.main.loadNibNamed("VideoControlView", owner: self, options: nil)?[0] as? VideoControlView)!
    }
    
    
//    @objc fileprivate func playbackSliderValueChanged(_ slider:ATPlayerSlider){
//
//        self.sliderValueChanged?(slider, .ended)
//    }
    
    @objc fileprivate func playbackSliderTouched(sender: UITapGestureRecognizer){
        
        guard let slider = sender.view as? ATPlayerSlider else{
            return
        }
        
        if slider.isHighlighted { return }
        
        let point = sender.location(in: slider)
        let percentage = Float(point.x / slider.bounds.width)
        let delta = percentage * (slider.maximumValue - slider.minimumValue)
        let value = slider.minimumValue + delta
        slider.setValue(value, animated: true)
        self.sliderValueChanged?(slider, .ended)
    }
    
    
    @objc fileprivate func onSliderValueChanged(_ slider: ATPlayerSlider, withEvent event: UIEvent) {
        
        guard let touchEvent = event.allTouches?.first else {
            return
        }
        
        self.sliderValueChanged?(slider, touchEvent.phase)
    }
    
    //MARK:- Actions
    @IBAction fileprivate func btnHDAndSDTouched(_ sender: Any) {
        
        self.btnHDAndSD.isSelected  = !self.btnHDAndSD.isSelected
        self.btnHDAndSDTrigger?(self.btnHDAndSD.isSelected)
        let title = self.btnHDAndSD.isSelected ? "SD" : "HD"
        self.btnHDAndSD.setTitle(title, for: .normal)
        
//        if self.btnHDAndSD.isSelected{
//
//            self.btnHDAndSD.setTitle("SD", for: .normal)
//        }else{
//
//            self.btnHDAndSD.setTitle("HD", for: .normal)
//        }
    }
    
    @IBAction fileprivate func btnToggleScreenTouched(_ sender: UIButton) {
        
        self.btnToggleScreen.isSelected  = !self.btnToggleScreen.isSelected
        if btnToggleScreen.isSelected{
            
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            self.btnToggleScreen.setImage(imageFullScreenExit, for: .normal)
        }else{
            
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            self.btnToggleScreen.setImage(imageFullScreen, for: .normal)
        }
    }
}


final class WeakTimer {
    private weak var timer: Timer?
    private weak var target: AnyObject?
    private let action: (Timer) -> Void
    
    private init(timeInterval: TimeInterval,
                 target: AnyObject,
                 repeats: Bool,
                 userInfo: Any?,
                 action: @escaping (Timer) -> Void) {
        self.target = target
        self.action = action
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(fire(timer:)), userInfo: userInfo, repeats: repeats)
        RunLoop.main.add(self.timer!, forMode: .common)

    }
    
    public class func scheduledTimer(timeInterval: TimeInterval,
                              target: AnyObject,
                              userInfo: Any?,
                              repeats: Bool,
                              action: @escaping (Timer) -> Void) -> Timer {
        return WeakTimer(timeInterval: timeInterval,
                         target: target,
                         repeats: repeats,
                         userInfo: userInfo,
                         action: action).timer!
    }
    
    @objc fileprivate func fire(timer: Timer) {
        if target != nil {
            action(timer)
        } else {
            timer.invalidate()
        }
    }
}
