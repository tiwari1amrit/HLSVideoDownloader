//
//  ATPlayerSlider.swift
//  HighlightsNepal
//
//  Created by Creator-$ on 12/15/17.
//  Copyright © 2017 tiwariammit@gmail.com. All rights reserved.
//

import UIKit

open class ATPlayerSlider: UISlider {
    
    open var progressView : UIProgressView = UIProgressView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureSlider(isShowImage: false)
        
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        configureSlider(isShowImage: false)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newRect = CGRect(x: rect.origin.x, y: rect.origin.y + 1, width: rect.width, height: rect.height)
        return newRect
    }
    
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        let newRect = CGRect(origin: rect.origin, size: CGSize(width: rect.size.width, height: 2.0))
        configureProgressView(newRect)
        return newRect
    }
    
    fileprivate func configureSlider(isShowImage: Bool) {
        minimumValue = 0.0
        value = 0.0
        
        minimumValue = 0
        maximumValue = 1.0 //Its depend upon
        isContinuous = true
        tintColor = .green
        
        self.changeSliderThumbImage(isShowImage: isShowImage)

        //backgroundColor = UIColor.clear
        progressView.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7988548801)
        progressView.trackTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2964201627)
    }
    
    public func changeSliderThumbImage(isShowImage : Bool){
        
        let maxTrackColor : UIColor = .white
        let minTrackColor : UIColor = .red
        
        maximumTrackTintColor = maxTrackColor
        
        var thumbImage = #imageLiteral(resourceName: "seek")
        
        if isShowImage == false{
            thumbImage = UIImage()
            minimumTrackTintColor = maxTrackColor
            
        }else{
            minimumTrackTintColor = minTrackColor
        }
        
        thumbImage = thumbImage.maskWithColor(color: .red)
        
        let normalThumbImage = ATPlayerUtils.imageSize(image: thumbImage, scaledToSize: CGSize(width: 20, height: 20))
        
        setThumbImage(normalThumbImage, for: .normal)
        let highlightedThumbImage = ATPlayerUtils.imageSize(image: thumbImage, scaledToSize: CGSize(width: 30, height: 30))
        setThumbImage(highlightedThumbImage, for: .highlighted)
    }
    
    func configureProgressView(_ frame: CGRect) {
        progressView.frame = frame
        insertSubview(progressView, at: 0)
    }
    
    open func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
}
