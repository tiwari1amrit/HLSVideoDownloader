//
//  VideoPlayer.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 12/24/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//

import UIKit
import AVFoundation


class VideoPlayerVC: UIViewController {

    @IBOutlet weak var videoPlayerView: UIView!
    
    
    let atVideoController = ATVideoPlayerView.loadFromNib()

    var relativePath : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.videoPlayerView.addSubview(atVideoController)
        
//        let urlString = "https://mnmott.nettvnepal.com.np/test01/sample_enc.mp4"

//        let localAsset = AVURLAsset(url: relativePath!)

        self.atVideoController.playVideo(relativePath!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.atVideoController.reInitiallizeObserver()

    }
   
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        UIApplication.shared.isStatusBarHidden = false
        NotificationCenter.default.removeObserver(self)
        
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeInstance()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // UIApplication.shared.isStatusBarHidden = false
        
        if UIApplication.shared.statusBarOrientation.isPortrait{
            self.navigationController?.isNavigationBarHidden = false
            UIApplication.shared.isStatusBarHidden = false
            
            let height = self.view.bounds.height * 0.35
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height)
            self.videoPlayerView.frame = frame
            self.atVideoController.videoProtraitModeScreenFrame = frame
     
        }else{
            self.navigationController?.isNavigationBarHidden = true
            UIApplication.shared.isStatusBarHidden = true
            
            let height = self.view.bounds.height
            
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height)
            self.videoPlayerView.frame = frame
            self.atVideoController.videoLandScapeModeScreenFrame = frame
        }
        
        self.view.layoutIfNeeded()
    }
    
    func removeInstance(){
        
        self.atVideoController.removeObserverAndPlayer()
        self.atVideoController.delegate = nil
        self.atVideoController.removeFromSuperview()
    }


}



extension URL {
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("isHidden error:", error)
            }
        }
    }
}
