//
//  ATVideoPlayerView.swift
//  ATVideoPlayer
//
//  Created by Amrit Tiwari on 4/18/18.
//  Copyright © 2018 tiwariammit@gmail.com. All rights reserved.
//

import UIKit
import AVKit

@objc protocol ATVideoPlayerViewDelegate : class{
    
    @objc optional func errorMessage(_ errorMessage : String, withErrorCode code : Int)
    @objc optional func playerDidFinishPlaying()
    @objc optional func btnShowErrorMessageTouched()
    @objc optional func notifyWhenVideoCapture()
    @objc optional func btnHDAndSDTouched(_ isSelected: Bool)
    @objc optional func didRotrateScreen(_ isProtrait : Bool)
    @objc optional func willEnterForeground()
    @objc optional func controlShowHideTrigger(_ isHidden : Bool)
    @objc optional func getCurrentTime(_ currentTime : Double)
    @objc optional func observerPeriodicTime(_ currentTime : Double)
    @objc optional func sliderValueChanged(_ slider : ATPlayerSlider, withTouchedPhase phase : UITouch.Phase)
}

enum VideoErrorCode : Int {
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case gone = 410

}

@objc public class ATVideoPlayerView: UIView {
    
    //MARK:- Outlets
    @IBOutlet weak var videoPlayerView: UIView!
    
    //for player
    fileprivate  var playerLayer : AVPlayerLayer?
    fileprivate var observer:Any?
    
    public lazy var btnPlayPause: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: self.heightAndWidthOfPlayAndExitButton, height: self.heightAndWidthOfPlayAndExitButton))
        let viewSize = CGSize(width: self.heightAndWidthOfPlayAndExitButton, height: self.heightAndWidthOfPlayAndExitButton)
        btn.frame.size = viewSize
        btn.addTarget(self, action: #selector(self.btnPlayPauseTouched(_:)), for: .touchUpInside)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        self.layoutIfNeeded()
        btn.setImage(self.imagePause, for: .normal)
        return btn
    }()
    
    lazy var btnShowErrorMessage: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: self.frame.width * 0.7, height: self.heightAndWidthOfPlayAndExitButton))
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.numberOfLines = 0
        btn.addTarget(self, action: #selector(self.btnShowErrorMessageTouched(_:)), for: .touchUpInside)
        return btn
    }()
    
    
    //timer to check the player items status (to find error on player)
    fileprivate  var timerTofindPlayerError : Timer?
    //timer to hide and show control items
    fileprivate var timerToHideAndShowControls : Timer?
    //fileprivate var sliderSeekControlTimer : Timer?

    
    fileprivate var videoPlayerTapGuesture = UITapGestureRecognizer()
    
    @objc fileprivate var lblMovingUserIDForTracking = UILabel()
    @objc fileprivate var timerForMovingLabel : Timer?
    
    fileprivate var isHideControl : Bool = false
    fileprivate var isVideoBuffering : Bool = true
     var dvrPlayerTotalTime: Float = 0.0// this is used to show playhead duration on sliding slider for DVR player
    
    //Below are the publicly change variable according to the user needs
    //for displaying user ID
    @objc public var userID : String?{
        didSet{
            self.setUpDisplayUserIdLabel()
        }
    }
    @objc public var showUserIDTimeInterval : TimeInterval = 20
    
    //message when users capture video!!!
    @objc public var youCantRecordVideo = "You can't record video."
    
    @objc public var atPlayer : AVPlayer?
    
    //this is the hide and width of play pause button and exit and enter full screen
    @objc public var heightAndWidthOfPlayAndExitButton: CGFloat = 44
    
    //for image
    @objc public var imagePlay = UIImage(named: "play")
    @objc public var imagePause = UIImage(named: "pause")
    
    @objc var isHideVideoControlView : Bool = false
    @objc var videoControlView = VideoControlView.loadFromNib()
    @objc public var videoControlViewHeight : CGFloat = 50
    @objc public var controlViewColor : UIColor = .black
    @objc weak var delegate : ATVideoPlayerViewDelegate?
    
    @objc public var isBtnHDAndSDHidden : Bool = true // default hidden btnHDSDButton
    
    //time to hide and show control view and play pause button
    @objc public var timeToHideAndShowControl : TimeInterval = 5
    
    //this is used for dvr player
    @objc public var isDVRPlayer : Bool = false
    @objc public lazy var activityIndicator: UIActivityIndicatorView = {
        
        let act = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.whiteLarge)
        act.tintColor = UIColor.white
        return act
    }()
    
    @objc public var isVideoIsBuffering: ((Bool)->())?
    
    //frame static frame for ATVideoPlayer on Protrait mode
    //you can change it according to your demand from you view controller
    @objc public lazy var videoProtraitModeScreenFrame : CGRect = {
        
        if #available(iOS 11.0, *) {
            
            let viewFrameWithSafeArea = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame
            let frame = CGRect(x: 0, y: 0, width: viewFrameWithSafeArea.width, height: viewFrameWithSafeArea.height * 0.5)
            return frame
        }else{
            
            let size = UIApplication.shared.keyWindow!.layoutMarginsGuide.layoutFrame
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.5)
            return frame
        }
    }()
    
    //frame static frame for ATVideoPlayer on landscape mode
    //you can change it according to your demand from you view controller
    @objc public lazy var videoLandScapeModeScreenFrame : CGRect = {
        
        if #available(iOS 11.0, *) {
            
            let viewFrameWithSafeArea = UIApplication.shared.keyWindow!.safeAreaLayoutGuide.layoutFrame
            
            let frame = CGRect(x: 0, y: 0, width: viewFrameWithSafeArea.width, height: viewFrameWithSafeArea.height)
            return frame
        }else{
            
            let size = UIApplication.shared.keyWindow!.layoutMarginsGuide.layoutFrame//UIScreen.main.bounds
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            return frame
        }
    }()
    
    
    @objc public class func loadFromNib() -> ATVideoPlayerView{
        
        return (Bundle.main.loadNibNamed("ATVideoPlayerView", owner: self, options: nil)?[0] as? ATVideoPlayerView)!
    }
    
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.videoControlView.movieSlider?.isUserInteractionEnabled = false
        self.videoControlView.loadingIndicator.color = .red
        self.addSubview(self.activityIndicator)
        self.addSubview(self.btnPlayPause)
        self.addSubview(self.btnShowErrorMessage)
        self.btnShowErrorMessage.setTitle("", for: .normal)
        self.btnPlayPause.isSelected = false
        
        self.addSubview(self.videoControlView)
        self.videoControlView.sliderValueChanged = { [weak self] (slider, phase) in
            guard let strongSelf = self else {return}
            
            strongSelf.sliderValueChanged(slider, withTouchedPhase: phase)
        }
        
        self.videoControlView.btnHDAndSDTrigger = {[weak self] isSelected in
            guard let strongSelf = self else {return}
            
            strongSelf.btnHDAndSDTouched(isSelected)
        }
        
        self.videoPlayerTapGuesture.numberOfTapsRequired = 1
        self.videoPlayerTapGuesture.addTarget(self, action: #selector(self.viewTouched))
        self.addGestureRecognizer(self.videoPlayerTapGuesture)
        self.videoPlayerTapGuesture.cancelsTouchesInView = false
        
        // self.btnPlayPause.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.reframeVideoPlayer()
    }
    
    //MARK:- Reframe Video Player
    fileprivate func reframeVideoPlayer(){
        
        if UIApplication.shared.statusBarOrientation.isPortrait{
            
            let frameChangeDueToNavBar = CGRect(x: 0, y: 0, width: videoProtraitModeScreenFrame.width, height: videoProtraitModeScreenFrame.height)
            
            self.frame = frameChangeDueToNavBar
            
            self.videoPlayerView.frame = self.bounds
            self.playerLayer?.frame = self.videoPlayerView.bounds
            
            self.videoControlView.btnToggleScreen.setImage(self.videoControlView.imageFullScreen, for: .normal)
            self.videoControlView.videoControlViewWidthConstraint.constant = self.frame.width - 20
            
            let yPostionForVieoControlView = self.videoPlayerView.bounds.height - self.videoControlViewHeight
            self.videoControlView.frame = CGRect(x: 0, y: yPostionForVieoControlView, width: self.frame.width, height: self.videoControlViewHeight)
        }else{
            
            let appDelagate = UIApplication.shared.delegate as! AppDelegate
            let window = appDelagate.window
            
            var yPosition: CGFloat = 0
            var leading: CGFloat = 0
            var trailing: CGFloat = 0
            
            if #available(iOS 11.0, *) {
                if let bottom = window?.safeAreaInsets.bottom, bottom > 0{
                    yPosition = bottom
                }
                if let left = window?.safeAreaInsets.left, left > 0{
                    leading = left
                }
                
                if let left = window?.safeAreaInsets.left, left > 0{
                    trailing = left
                }
            }
            
            self.frame = videoLandScapeModeScreenFrame
            self.videoPlayerView.frame = self.frame
            self.playerLayer?.frame = self.videoPlayerView.bounds
            self.playerLayer?.frame.size.height = self.videoPlayerView.bounds.height - yPosition
            
            self.videoControlView.btnToggleScreen.setImage(self.videoControlView.imageFullScreenExit, for: .normal)
            
            let safeAreaWidth = leading + trailing
            self.videoControlView.videoControlViewWidthConstraint.constant = self.frame.width - 20 - safeAreaWidth
            
            self.videoControlView.frame = CGRect(x: leading, y: self.bounds.height - self.videoControlViewHeight - yPosition, width: self.frame.width - safeAreaWidth, height: self.videoControlViewHeight)
        }
        
        self.btnPlayPause.frame = CGRect(x: (self.videoPlayerView.frame.width/2) - heightAndWidthOfPlayAndExitButton/2, y: (self.videoPlayerView.frame.height/2) - heightAndWidthOfPlayAndExitButton/2, width: heightAndWidthOfPlayAndExitButton, height: heightAndWidthOfPlayAndExitButton)
        
        self.activityIndicator.frame = self.btnPlayPause.frame
        
        btnShowErrorMessage.frame = self.btnPlayPause.frame
        btnShowErrorMessage.frame.size.width = self.frame.width * 0.6
        btnShowErrorMessage.frame.origin.x = self.frame.width/2 - btnShowErrorMessage.frame.width/2
        self.layoutIfNeeded()
    }
    
    //MARK:- Video Player
    @objc public func playVideo(_ urls : URL){
        
        if let observer = self.observer{
            
            self.atPlayer?.removeTimeObserver(observer)
        }
        self.observer = nil
        
        self.atPlayer?.pause()
        self.removeObserverAndPlayer()
        print(urls)
//        let urlString = "https://mnmott.nettvnepal.com.np/test01/sample.mp4/playlist.m3u8"
//        let urls = URL(string: urlString)!
        var urlComponents = URLComponents(url: urls, resolvingAgainstBaseURL: false)
//        urlComponents?.scheme = "fakehttps"
        let avAsset = AVURLAsset(url: urlComponents!.url!, options: nil)
        
        avAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.global(qos: .background))
        let avplayerItem = AVPlayerItem(asset: avAsset)
        self.atPlayer = AVPlayer(playerItem: avplayerItem)//AVPlayer(url: url)
        
        let encriptionKey = "29080ACF01787DBF091567C49A81DDD9"

        let keyFileName = "\(encriptionKey).key"
        
        do {
            
            // ***** Create key file *****
            let keyFilePath = "ckey://\(keyFileName)"
            
            let fileManager = FileManager.init()
            let subDirectories = try fileManager.contentsOfDirectory(at: urls,includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            
            for url in subDirectories {
                
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    
                    if isDirectory.boolValue {
                        
                        let path = url.path as NSString
                        
                        let folderName = path.lastPathComponent
                        let playlistFilePath = path.appendingPathComponent("\(folderName).m3u8")
                        
                        if fileManager.fileExists(atPath: playlistFilePath) {
                            
                            var fileContent = try String.init(contentsOf: URL.init(fileURLWithPath: playlistFilePath))
                            
                            let stringArray = self.matches(for: "URI=\"(.+?)\"", in: fileContent)

                            for pattern in stringArray {
                                fileContent = fileContent.replacingOccurrences(of: pattern, with: "URI=\"\(keyFilePath)\"")
                            }
                            
                            try fileContent.write(toFile: playlistFilePath, atomically: true, encoding: .utf8)
                        }
                        
                        let streamInfoXML = path.appendingPathComponent("StreamInfoBoot.xml")
                        
                        if fileManager.fileExists(atPath: streamInfoXML) {
                            
                            var fileContent = try String.init(contentsOf: URL.init(fileURLWithPath: streamInfoXML))
                            fileContent = fileContent.replacingOccurrences(of: "https:", with: "fakehttps:")
                            try fileContent.write(toFile: streamInfoXML, atomically: true, encoding: .utf8)
                        }
                    } else {
                        
                        if url.lastPathComponent == "boot.xml" {
                            
                            let bootXML = url.path
                            
                            if fileManager.fileExists(atPath: bootXML) {
                                
                                var fileContent = try String.init(contentsOf: URL.init(fileURLWithPath: bootXML))
                                fileContent = fileContent.replacingOccurrences(of: "https:", with: "fakehttps:")
                                try fileContent.write(toFile: bootXML, atomically: true, encoding: .utf8)
                            }
                        }
                    }
                }
            }
            var userInfo : [String: AnyObject] = [:]
//            userInfo[Asset.Keys.state] = Asset.State.downloaded.rawValue
//
//            // Update download status to db

        } catch  {
        }
        
        

//
////        let avplayerItem = AVPlayerItem(asset: avUrlAsset)
//////        let avplayerItem = AVPlayerItem(url: url)
////        self.atPlayer = AVPlayer(playerItem: avplayerItem)//AVPlayer(url: url)
        
        
        self.playerLayer = AVPlayerLayer(player: atPlayer!)
        self.videoPlayerView.layer.addSublayer(self.playerLayer!)
//
        self.atPlayer?.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
        self.atPlayer?.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        self.reframeVideoPlayer()
        self.playerLayer?.backgroundColor = UIColor.black.cgColor
        self.videoControlView.lblTotalTime.text = "--:--"

        self.btnPlayPause.layer.zPosition = 1
        self.activityIndicator.layer.zPosition = 1
        self.videoControlView.layer.zPosition = 1
        self.btnShowErrorMessage.layer.zPosition = 1
        self.btnShowErrorMessage.isHidden = true

        self.videoControlView.isHidden = self.isHideVideoControlView ? true : false

        self.atPlayer?.play()
        if #available(iOS 10.0, *) {
            self.atPlayer?.playImmediately(atRate: 1)
        } else {
            // Fallback on earlier versions
        }
        self.reInitiallizeObserver()
        self.btnPlayPause.isHidden = true
        self.isVideoIsBuffering?(true)
        self.isVideoBuffering = true
        self.videoControlView.movieSlider?.isUserInteractionEnabled = false
        self.videoControlView.movieSlider.changeSliderThumbImage(isShowImage:false)
        self.videoControlView.loadingIndicator.isHidden = false
        self.videoControlView.lblCurrentTime.isHidden = true
    }
    
    
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    //MARK:- ***** Observer *****
    @objc public func reInitiallizeObserver(){
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector:#selector(self.playerDidFinishPlaying(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: atPlayer?.currentItem)
        
        NotificationCenter.default.addObserver(self,selector:#selector(self.playerItemFailedToPlayToEndTime(note:)),name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: atPlayer?.currentItem)

        NotificationCenter.default.addObserver(self, selector: #selector(self.playerStalled(_:)),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: self.atPlayer?.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground(note:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(self.detectVideoCapture), name: UIScreen.capturedDidChangeNotification, object: nil)
        } else {
            // Fallback on earlier versions
        }
        
        self.detectVideoCapture()
        self.startTimerTofindPlayerError()
        self.periodicTimeObsever(nil)
        self.startTimerToControlCustomControl()
        
        self.videoControlView.backgroundColor = controlViewColor
        self.videoControlView.btnHDAndSD.isHidden = isBtnHDAndSDHidden
        self.videoControlView.btnHDAndSDView.isHidden = isBtnHDAndSDHidden
    }
    
    
    
    @objc fileprivate func detectVideoCapture(){
        
        if #available(iOS 11.0, *) {
            let isCaptured = UIScreen.main.isCaptured
            
            if isCaptured{
                self.delegate?.notifyWhenVideoCapture?()
            }
        }
    }
    
    // Observer Time
    fileprivate func periodicTimeObsever(_ slider : ATPlayerSlider?){
        
        if let observer = self.observer{
            
            self.atPlayer?.removeTimeObserver(observer)
        }
        self.observer = nil
        self.activityIndicator.startAnimating()
        self.isVideoBuffering = true
        
        let intervel : CMTime = CMTimeMake(value: 1, timescale: 10)
        self.observer = self.atPlayer?.addPeriodicTimeObserver(forInterval: intervel, queue: DispatchQueue.main) { [weak self] time in
            
            guard let strongSelf = self else{return}
            
            if strongSelf.isDVRPlayer{
                _ = strongSelf.getLiveDurationForDVR()
                strongSelf.videoControlView.lblTotalTime.text = "Live"
            }
            
            let sliderValue : Float64 = CMTimeGetSeconds(time)
            if sliderValue > 0.0{
                strongSelf.videoControlView.movieSlider?.isUserInteractionEnabled = true
                strongSelf.videoControlView.movieSlider.changeSliderThumbImage(isShowImage: true)
                strongSelf.videoControlView.movieSlider.value =  Float(sliderValue)
                strongSelf.setUpSliderTime()
                strongSelf.videoControlView.loadingIndicator.isHidden = true
                strongSelf.videoControlView.lblCurrentTime.isHidden = false
            }else{
                strongSelf.videoControlView.loadingIndicator.isHidden = false
                strongSelf.videoControlView.lblCurrentTime.isHidden = true
            }
            
            let playbackLikelyToKeepUp = strongSelf.atPlayer?.currentItem?.isPlaybackLikelyToKeepUp
            if playbackLikelyToKeepUp == false{
                
                strongSelf.activityIndicator.startAnimating()
                strongSelf.btnPlayPause.isHidden = true
                strongSelf.isVideoIsBuffering?(true)
                strongSelf.isVideoBuffering = true
            }else{
                
                strongSelf.activityIndicator.stopAnimating()
                strongSelf.isVideoIsBuffering?(false)
                strongSelf.isVideoBuffering = false
                
                strongSelf.btnPlayPause.isHidden = strongSelf.videoControlView.isHidden
            }
            if let currentItem = strongSelf.atPlayer?.currentItem {
                // Get the current time in seconds
                let playhead = currentItem.currentTime().seconds
                if playhead.isFinite{
                    strongSelf.delegate?.observerPeriodicTime?(playhead)
                }
            }
        }
    }
    
    
    //MARK:-Video Dimentions
    func resolutionSizeVideo(_ url:URL) -> CGSize? {
        guard let track = AVAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        
//        track.asset.
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    
    //MARK:- ***** De-initiallized *****
    deinit {
        print("ATPlayer deinitiallized")
        self.removeObserverAndPlayer()
    }
    
    
    @objc public func removeObserverAndPlayer(){
        
        if let observer = self.observer{
            
            self.atPlayer?.removeTimeObserver(observer)
        }
        self.observer = nil
        NotificationCenter.default.removeObserver(self)
        
        atPlayer?.pause()
        atPlayer = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        self.timerToHideAndShowControls?.invalidate()
        self.timerToHideAndShowControls = nil
        
        self.timerTofindPlayerError?.invalidate()
        self.timerTofindPlayerError = nil
      
        self.timerForMovingLabel?.invalidate()
        self.timerForMovingLabel = nil
    }
    
    //MARK:-Display user id
    func setUpDisplayUserIdLabel() {
        
        self.lblMovingUserIDForTracking.removeFromSuperview()
        self.lblMovingUserIDForTracking.frame = CGRect(x: 0, y: self.frame.size.height / 2 - 25, width: 100, height: 50)
        self.lblMovingUserIDForTracking.textColor = UIColor.white
        self.lblMovingUserIDForTracking.backgroundColor = UIColor.clear
        
        self.lblMovingUserIDForTracking.text = self.userID
        self.addSubview(self.lblMovingUserIDForTracking)
        self.lblMovingUserIDForTracking.isHidden = true
        self.timerForMovingLabel?.invalidate()
        self.timerForMovingLabel = nil
        self.timerForMovingLabel = Timer.scheduledTimer(timeInterval: self.showUserIDTimeInterval, target: self, selector: #selector(self.showMovingLabel), userInfo: nil, repeats: true)
    }
    
    @objc func showMovingLabel() {
        
        self.lblMovingUserIDForTracking.layer.zPosition = 5
        self.lblMovingUserIDForTracking.isHidden = false
        
        let randomYPosition = CGFloat(arc4random_uniform(UInt32(self.frame.height)))
        let randomXPosition = CGFloat(arc4random_uniform(UInt32(self.frame.width)))
        
        UIView.animate(withDuration: 4, animations: { [weak self] in
            guard let this = self else{
                return
            }
            this.lblMovingUserIDForTracking.frame = CGRect(x: randomXPosition, y: randomYPosition, width: 100, height: 50)
            
        }) { [weak self] (finished) in
            
            guard let this = self else{
                return
            }
            this.lblMovingUserIDForTracking.isHidden = true
        }
    }
    
    
    //MARK:- ***** Timer *****
    
    //MARK:- for know error in player
    fileprivate func startTimerTofindPlayerError(){
        self.timerTofindPlayerError?.invalidate()
        self.timerTofindPlayerError = nil
        //        self.timerTofindPlayerError = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.timerTofindPlayerErrorTrigger), userInfo: nil, repeats: true)
        self.timerTofindPlayerError = WeakTimer.scheduledTimer(timeInterval: 3, target: self, userInfo: nil, repeats: true, action: { [weak self] (timer) in
            guard let strongSelf = self else { return }
            strongSelf.timerTofindPlayerErrorTrigger()
        })
    }    
 
    
    @objc fileprivate func timerTofindPlayerErrorTrigger(){
        
        guard let currentItems = self.atPlayer?.currentItem else{
            return
        }
        
        let status = currentItems.status
        
//        guard let errorLog = currentItems.errorLog() else {
//
//            return
//        }
//        print(errorLog)
        
        switch status {
        case .readyToPlay:
            
            return
        // Player item is ready to play.
        case .failed, .unknown:
            guard let error = currentItems.error else {
                return
            }
            
        
            self.handleUrlErroronPlayer(error)
            
//        case .unknown:
//
//            guard let error = currentItems.error else {
//                return
//            }
//            self.handleUrlErroronPlayer(error)
            
        }
    }
    
    
    fileprivate func handleUrlErroronPlayer(_ error : Error){
        
        print("ATPlayer Error:- \(error)")
        var tempErrorMessage: String?
        var code = VideoErrorCode.unauthorized.rawValue
        if let errors = error as NSError?{
            tempErrorMessage = errors.localizedFailureReason
            code = errors.code
           // if errors.domain == AVFoundationErrorDomain{
                
        }
        
        if tempErrorMessage == nil{
            tempErrorMessage = error.localizedDescription
        }
        let errorMessage = tempErrorMessage ?? "Oops! no video here"
        
        self.removeObserverAndPlayer()
        
        self.btnShowErrorMessage.isHidden = false
        self.btnShowErrorMessage.setTitle(errorMessage + ". Try again", for: .normal)
        self.playerSliderViewStatus(true)
        self.delegate?.errorMessage?(errorMessage, withErrorCode: code)
    }
    
    //MARK:- for hide and show control
    fileprivate func startTimerToControlCustomControl(){
        
        self.timerToHideAndShowControls?.invalidate()
        self.timerToHideAndShowControls = nil
        self.timerToHideAndShowControls = Timer.scheduledTimer(timeInterval: self.timeToHideAndShowControl, target: self, selector: #selector(self.timerTrigger), userInfo: nil, repeats: false)
    }
    
    
    @objc fileprivate func timerTrigger(){
        
        self.playerSliderViewStatus(true)
    }
    
    
    fileprivate func playerSliderViewStatus(_ isHidden : Bool){
        
        self.isHideControl = isHidden
        self.videoControlView.isHidden = self.isHideVideoControlView ? true : isHidden
        //self.videoControlView.isHidden = isHidden
        self.btnPlayPause.isHidden = self.isVideoBuffering ? true : isHidden
        self.delegate?.controlShowHideTrigger?(isHidden)
    }
    
    
    //MARK:-Observed Methods
    @objc fileprivate func btnPlayPauseTouched(_ sender: UIButton) {
        
        self.btnPlayPause.isSelected = !self.btnPlayPause.isSelected
        if btnPlayPause.isSelected{
            
            self.btnPlayPause.setImage(imagePlay, for: .normal)
            atPlayer?.pause()
        }else{
            
            atPlayer?.play()
            self.btnPlayPause.setImage(imagePause, for: .normal)
        }
        
        self.playerSliderViewStatus(false)
        self.startTimerToControlCustomControl()
    }
    
    
    //when rotating the device.
    @objc fileprivate func rotated() {
        
        if UIApplication.shared.statusBarOrientation.isPortrait{
            print("isPortrait")
            self.delegate?.didRotrateScreen?(true)
        }else{
            self.delegate?.didRotrateScreen?(false)
            print("Landscape")
        }
        reframeVideoPlayer()
    }
    
    
    @objc fileprivate func viewTouched(){
        
        if self.isHideControl{
            
            self.playerSliderViewStatus(false)
            
        }else{
            
            self.playerSliderViewStatus(true)
        }
        self.startTimerToControlCustomControl()
    }
    
    //when player did finished playing
    @objc fileprivate func playerDidFinishPlaying(note: NSNotification){
        print("Video Finished")
        self.delegate?.playerDidFinishPlaying?()
    }
    
    
    @objc fileprivate func playerItemFailedToPlayToEndTime(note: NSNotification){
        print(note)
        guard let userInfo = note.userInfo else {
            return
        }
        print(userInfo)
    }
    
    @objc fileprivate func playerStalled(_ note : Notification){
        
        self.activityIndicator.startAnimating()
        self.btnPlayPause.isHidden = true
        self.isVideoIsBuffering?(true)
        self.isVideoBuffering = true
    }
  
    
    @objc fileprivate func willEnterForeground(note: NSNotification){
        
        self.atPlayer?.play()
        self.btnPlayPause.isSelected = false
        self.btnPlayPause.setImage(self.imagePause, for: .normal)
        self.delegate?.willEnterForeground?()
    }
    
    
    @objc fileprivate func btnShowErrorMessageTouched(_ sender: UIButton){
        
        self.removeObserverAndPlayer()
        self.btnShowErrorMessage.isHidden = true
        self.delegate?.btnShowErrorMessageTouched?()
    }
    
    
    //this is only used in dvr player
    func getLiveDurationForDVR() -> Float {
        var dvrTotalTime : Float = 0.0
        
        guard let items = self.atPlayer?.currentItem, items.seekableTimeRanges.count > 0 else {
            return dvrTotalTime
        }
        let ranges = items.seekableTimeRanges
        let range = ranges[ranges.count - 1]
        let timeRange = range.timeRangeValue
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        dvrTotalTime = Float(startSeconds + durationSeconds)
        dvrPlayerTotalTime = dvrTotalTime
        self.videoControlView.movieSlider.maximumValue = dvrTotalTime
        self.videoControlView.movieSlider.minimumValue = Float(startSeconds)
        let currentTime = items.currentTime().seconds

        if currentTime.isInfinite{
            return dvrTotalTime
        }
        
        var difference = durationSeconds + startSeconds - currentTime
        if difference == 0{
            self.videoControlView.lblCurrentTime.text = "Live"
        }else{
            if difference < 0{
                difference = -difference
            }
            self.videoControlView.lblCurrentTime.text = "-" + TimeFormat.formatTimeFor(Double(difference))
        }
        
        return dvrTotalTime
    }
    
    
    
    //MARK:-Time set up of slider
    fileprivate func setUpSliderTime(){
        if self.isDVRPlayer{
            return// time is not set for dvr we are showing current time in negative format
        }
        
        if let currentItem = self.atPlayer?.currentItem {
            // Get the current time in seconds
            let playhead = currentItem.currentTime().seconds
            let duration = currentItem.duration.seconds
            // Format seconds for human readable string
            
            if playhead.isFinite{
                self.videoControlView.lblCurrentTime.text = TimeFormat.formatTimeFor(playhead)
                self.delegate?.getCurrentTime?(playhead)
            }
            
            if duration.isFinite{
                
                self.videoControlView.lblTotalTime.text = TimeFormat.formatTimeFor(duration)
                self.videoControlView.movieSlider.maximumValue = Float(duration)
            }
        }
    }
    
    
    fileprivate func sliderValueChanged(_ slider : ATPlayerSlider, withTouchedPhase phase : UITouch.Phase){
        
        self.delegate?.sliderValueChanged?(slider, withTouchedPhase: phase)
        
        if let observer = self.observer{
            
            self.atPlayer?.removeTimeObserver(observer)
        }
        self.observer = nil
        self.atPlayer?.pause()
        let seconds : Int64 = Int64(slider.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        self.activityIndicator.startAnimating()
        self.atPlayer?.currentItem?.cancelPendingSeeks()
        slider.setValue(Float(seconds), animated: true)
        
        let playhead = Double(seconds)
        
        if isDVRPlayer{
            let difference = self.dvrPlayerTotalTime - Float(playhead)
            if difference == 0{
                self.videoControlView.lblCurrentTime.text = "Live"
            }else{
                self.videoControlView.lblCurrentTime.text = "-" + TimeFormat.formatTimeFor(Double(difference))
            }
        }else{
            self.videoControlView.lblCurrentTime.text = TimeFormat.formatTimeFor(playhead)
        }
        
        self.playerSliderViewStatus(false)

        if phase != .ended{
            self.atPlayer?.pause()
            return
        }
        
        self.periodicTimeObsever(slider)
        self.atPlayer?.seek(to: targetTime)
        
        if self.atPlayer?.rate == 0{
            self.atPlayer?.play()
        }
      
        self.btnPlayPause.isSelected = false
        self.btnPlayPause.setImage(self.imagePause, for: .normal)
        self.startTimerToControlCustomControl()
    }
    
    fileprivate func btnHDAndSDTouched(_ isSelected: Bool){
        self.delegate?.btnHDAndSDTouched?(isSelected)
    }
}


extension ATVideoPlayerView : AVAssetResourceLoaderDelegate, AVAssetDownloadDelegate{
    
    
    private func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection){
        print(assetDownloadTask)
    }
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return self.shouldLoadOrRenewRequestedResource(resourceLoadingRequest: renewalRequest)
    }
    
    
    func shouldLoadOrRenewRequestedResource(resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard var url = resourceLoadingRequest.request.url else {
            return false
        }
        
        //FETCH THE KEY FROM NETWORK CALL/KEYSTORE, CONVERT IT TO DATA AND FINISH LOADING OF RESOURCE WITH THAT DATA, IN YOUR CASE JOIN THE OTHER HALF OF THE KEY TO ACTUAL KEY (you can get the first half from the url above)
        
        let key = "7559A091A3C22EC1EA1C0F73301A994D"
        resourceLoadingRequest.dataRequest?.respond(with: Data(base64Encoded: key)!)
        resourceLoadingRequest.finishLoading()
        
        return true;
    }

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
        print(resourceLoader)
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print(resourceLoader)
    }
    
   
    
    private func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool{
        
        guard let dataRequest = loadingRequest.dataRequest,let url = loadingRequest.request.url,
            let contentRequest = loadingRequest.contentInformationRequest else { return false}
        
        
        guard var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false) else { return  false}
        components.scheme = "file"
        guard let localUrl = components.url else { return false }
        
        //        let storageProvider = StorageVideo()
        //        let dataMaybe = storageProvider.videoData(url: localUrl)
        
        //        guard let encryptedData = dataMaybe,
        //            let decryptedData = try? RNCryptor.decrypt(data: encryptedData,
        //                                                       withPassword: "omitted") else {
        //                                                        return false
        //        }
        //
        //        contentRequest.contentType = AVFileType.mp4.rawValue
        //        contentRequest.contentLength = Int64(decryptedData.count)
        //            contentRequest.isByteRangeAccessSupported = true
        //
        //        dataRequest.respond(with: decryptedData)
        //        loadingRequest.finishLoading()
        
        return true
    }
}

/*
 NotificationCenter.default.addObserver(self, selector: #selector(self.itemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: atPlayer?.currentItem)
 
 NotificationCenter.default.addObserver(self, selector: #selector(self.itemNewErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: atPlayer?.currentItem)
 
 NotificationCenter.default.addObserver(self, selector: #selector(self.itemPlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: atPlayer?.currentItem)
 
 }
 
 
 @objc func itemFailedToPlayToEndTime(_ notification: NSNotification){
 print(notification)
 }
 
 @objc func itemNewErrorLogEntry(_ notification: NSNotification){
 print(notification)
 }
 
 @objc func itemPlaybackStalled(_ notification: NSNotification){
 print(notification)
 }
 */
