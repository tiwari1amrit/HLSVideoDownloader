//
//  ViewController.swift
//  HLSVideoDownloader
//
//  Created by Amrit Tiwari on 1/9/19.
//  Copyright © 2019 Amrit Tiwari. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblProgress: UILabel!
    @IBOutlet weak var btnPauseResume: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnDownload: UIButton!
    
    var sources = [HLSion]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        self.lblProgress.isHidden = true
        self.progressView.isHidden = true
        self.btnCancel.isHidden = true
        self.btnPauseResume.isHidden = true
        
        //        let urlString = "https://mnmott.nettvnepal.com.np/test01/sample.mp4/playlist.m3u8"
        
//        let urlString = "https://mnmott.nettvnepal.com.np/test01/sample_movie.mp4/playlist.m3u8"
        
        let urlString = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"

        //        let urlString = "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        let url = URL(string: urlString)!
        sources.append(HLSion(url: url, name: "HLS: long Video"))
        
        
    }
    
    
    fileprivate func processDownload(){
        
        self.progressView.isHidden = false
        self.lblProgress.isHidden = false
        self.btnCancel.isHidden = false
        self.btnPauseResume.isHidden = false
        self.btnDownload.isHidden = true
        
        
    }
    
    
    //MARK:-Actions
    @IBAction func btnPlayVideoTouched(_ sender: Any) {
        
        let rawString = "https://mnmott.nettvnepal.com.np/test01/sample.mp4/chunk.m3u8"
        
//        let rawString = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        //let rawString = "https://mnmott.nettvnepal.com.np/test01/sample_movie.mp4/playlist.m3u8"
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlayerVC") as! VideoPlayerVC
        let path = URL(string: rawString)
        vc.relativePath = path
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnDownloadTouched(_ sender: Any){
        
        let hlsion = sources[0]
        
        switch hlsion.state {
        case .notDownloaded:
            
            hlsion.download { [weak self] (percent) in
                guard let `self` = self else { return}
                
                DispatchQueue.main.async {
                    print(percent)
                    self.progressView.isHidden = false
                    self.progressView.progress = Float(percent)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
//                    let progressD =  String(format: "%.1f%% of %@", progress * 100, totalSize)
//                    self.lblProgress.text = progressD
                }
                }.finish { [weak self] (localUrl) in
                    guard let `self` = self else { return}
                    
                    DispatchQueue.main.async {
                        print(hlsion.localUrl)
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlayerVC") as! VideoPlayerVC
                        vc.relativePath = hlsion.localUrl
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }.onError { (error) in
                    print("Error finish. \(error)")
            }
        case .downloading:
            self.progressView.isHidden = false
            break
        case .downloaded:
            self.progressView.isHidden = false
            DispatchQueue.main.async {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlayerVC") as! VideoPlayerVC
                vc.relativePath = hlsion.localUrl!
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        //
        //        let urlString = "http://ipv4.download.thinkbroadband.com/10MB.zip"
        ////        let urlString = "https://slack.com/ssb/download-osx-beta"
        ////        let urlString = rawString.replacingOccurrences(of: "/playlist.m3u8", with: "")
        //
        //        guard let url = URL(string: rawString) else { return }
        //        self.musicVideoDetails = MusicVideoDetail(previewURL: url)
        //        self.downloadManager.startDownload(musicVideoDetails)
        //        self.processDownload()
    }
    
    @IBAction func btnPauseResumeTouched(_ sender: UIButton){
        
        
        
        self.btnPauseResume.setTitle(title, for: UIControl.State())
    }
    
    @IBAction func btnCancelTouched(_ sender: Any){
//        self.downloadManager.cancelDownload(self.musicVideoDetails)
    }
    
}
