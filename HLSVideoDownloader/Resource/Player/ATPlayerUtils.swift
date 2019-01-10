//
//  ATPlayerUtils.swift
//  HighlightsNepal
//
//  Created by Creator-$ on 12/15/17.
//  Copyright © 2017 tiwariammit@gmail.com. All rights reserved.
//


import UIKit

public enum ATPlayerMediaFormat : String{
    case unknown
    case mpeg4
    case m3u8
    case mov
    case m4v
    case error
}

extension UIImage {
    
    func maskWithColor(color:UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else{
            return UIImage()
        }

        color.setFill()
        
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
        context.draw(self.cgImage!, in: rect)
        
        context.setBlendMode(CGBlendMode.sourceIn)
        context.addRect(rect)
        context.drawPath(using: CGPathDrawingMode.fill)
        
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return coloredImage!
    }
}


class ATPlayerUtils: NSObject {

   static func imageSize(image: UIImage, scaledToSize newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIColor.red.setFill()

        UIGraphicsEndImageContext()

        return newImage
    }
    
    static func decoderVideoFormat(_ URL: URL?) -> ATPlayerMediaFormat {
        if URL == nil {
           return .error
        }
        if let path = URL?.absoluteString{
            if path.contains(".mp4") {
                return .mpeg4
            } else if path.contains(".m3u8") {
                return .m3u8
            } else if path.contains(".mov") {
                return .mov
            } else if path.contains(".m4v"){
                return .m4v
            } else {
                return .unknown
            }
        } else {
            return .error
        }
    }
}
