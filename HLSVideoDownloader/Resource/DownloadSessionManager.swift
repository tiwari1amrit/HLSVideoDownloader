//
//  DownloadSessionManager.swift
//  ATMusicPlayer
//
//  Created by Amrit Tiwari on 9/28/18.
//  Copyright © 2018 Amrit Tiwari. All rights reserved.
//


import Foundation
import AVFoundation
import UIKit


final internal class DownloadSessionManager: NSObject, AVAssetDownloadDelegate {
    // MARK: Properties
    
    static let shared = DownloadSessionManager()
    
    internal let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
    public var downloadSession: AVAssetDownloadURLSession!
    internal var downloadingMap = [AVAssetDownloadTask : HLSion]()
    
    let configuration = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
    
    
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    
    // MARK: Intialization
    override private init() {
        super.init()
        
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: OperationQueue())
        
        restoreDownloadsMap()
    }
    
    
    private func restoreDownloadsMap() {
        
        downloadSession.getAllTasks { tasksArray in
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let hlsionName = task.taskDescription else { break }
                
                let urlAsset = assetDownloadTask.urlAsset
                let hlsion = HLSion(asset: urlAsset, description: hlsionName)
                self.downloadingMap[assetDownloadTask] = hlsion
                task.resume()
            }
        }
    }
    
    func downloadStream(_ hlsion: HLSion) {
        guard assetExists(forName: hlsion.name) == false else { return }
        
        guard let task = downloadSession.makeAssetDownloadTask(asset: hlsion.urlAsset, assetTitle: hlsion.name, assetArtworkData: nil, options: nil) else { return }
        
        task.taskDescription = hlsion.name
        downloadingMap[task] = hlsion
        
        task.resume()
    }
    
    //    func downloadAdditional(media: AVMutableMediaSelection, hlsion: HLSion) {
    //        guard assetExists(forName: hlsion.name) == true else { return }
    //
    //        let options = [AVAssetDownloadTaskMediaSelectionKey: media]
    //        guard let task = session.makeAssetDownloadTask(asset: hlsion.urlAsset, assetTitle: hlsion.name, assetArtworkData: nil, options: options) else { return }
    //
    //        task.taskDescription = hlsion.name
    //        downloadingMap[task] = hlsion
    //
    //        task.resume()
    //    }
    
    func cancelDownload(_ hlsion: HLSion) {
        downloadingMap.first(where: { $1 == hlsion })?.key.cancel()
    }
    
    func deleteAsset(forName: String) throws {
        guard let relativePath = AssetStore.path(forName: forName) else { return }
        let localFileLocation = homeDirectoryURL.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: localFileLocation)
        AssetStore.remove(forName: forName)
    }
    
    func assetExists(forName: String) -> Bool {
        guard let relativePath = AssetStore.path(forName: forName) else { return false }
        let filePath = homeDirectoryURL.appendingPathComponent(relativePath).path
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    // MARK: AVAssetDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
//        guard let task = task as? AVAssetDownloadTask , let hlsion = downloadingMap.removeValue(forKey: task) else { return }
        
        guard let assetDownloadTask = task as? AVAssetDownloadTask, let hlsion = downloadingMap[assetDownloadTask] else { return }

        if let error = error as? NSError {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                // hlsion.result as success when cancelled.
                guard let localFileLocation = AssetStore.path(forName: hlsion.name) else { return }
                
                do {
                    let fileURL = homeDirectoryURL.appendingPathComponent(localFileLocation)
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("An error occured trying to delete the contents on disk for \(hlsion.name): \(error)")
                }
                
            case (NSURLErrorDomain, NSURLErrorUnknown):
                hlsion.result = .failure(error)
                fatalError("Downloading HLS streams is not supported in the simulator.")
                
            default:
                hlsion.result = .failure(error)
                print("An unexpected error occured \(error.domain)")
            }
            
            if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                print(resumeData)
            }
            
            guard let urlString = error.userInfo[kCFURLErrorFailingURLStringErrorKey as String] as? String else{
                return
            }
                        
//            guard let hlsionName = assetDownloadTask.taskDescription else { return }
//            let urlAsset = assetDownloadTask.urlAsset
//            let hlsion = HLSion(asset: urlAsset, description: hlsionName)
//            self.downloadingMap[assetDownloadTask] = hlsion
//            assetDownloadTask.resume()
//
//
//            print(urlString)
            
        } else {
            hlsion.result = .success
        }
        guard let result = hlsion.result else{
            return
        }
        switch result {
        case .success:
            let name = hlsion.name
            guard let assetStore = AssetStore.path(forName: name) else {
                return
            }
            hlsion.finishClosure?(assetStore)
        case .failure(let err):
            hlsion.errorClosure?(err)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64){
        let progress =  Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToSend, countStyle: .file)
        print(totalSize)


    }
  
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {

        guard let hlsion = downloadingMap[assetDownloadTask] else { return }
        AssetStore.set(path: location.relativePath, forName: hlsion.name)
        let assetStore = AssetStore.path(forName: hlsion.name)
        hlsion.finishClosure?(assetStore!)
        
    }
    
    
    func urlSession(_ session: URLSession,assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],timeRangeExpectedToLoad: CMTimeRange) {
        
        guard let hlsion = downloadingMap[assetDownloadTask] else { return }
        hlsion.result = nil
        guard let progressClosure = hlsion.progressClosure else { return }
        
        let percentComplete = loadedTimeRanges.reduce(0.0) {
            let loadedTimeRange : CMTimeRange = $1.timeRangeValue
            return $0 + CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }
        
        let timeremaining = CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        let times = TimeFormat.formatTimeFor(timeremaining)
        
        print(times)
        progressClosure(percentComplete)
    }
    
    //    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
    //        if assetDownloadTask.taskDescription == "jp.HLSion.dummy" {
    //            guard let hlsion = downloadingMap[assetDownloadTask] else { return }
    //            hlsion.resolvedMediaSelection = resolvedMediaSelection
    //            assetDownloadTask.cancel()
    //        }
    //    }
}


extension DownloadSessionManager: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        return true
    }
}

extension DownloadSessionManager: URLSessionDelegate{
    
    // Standard background session handler
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            //            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            //                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
            //
            //                completionHandler()
            //                appDelegate.backgroundSessionCompletionHandler = nil
            //            }
            
            if let completionHandler = self.backgroundSessionCompletionHandler {
                self.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?){
        
        if let error = error{
            print(error)
        }
    }
}
