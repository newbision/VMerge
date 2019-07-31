//
//  MergeVideoViewController.swift
//  VMerge
//
//  Created by newbision on 8/22/18.
//  Copyright © 2018 newbision. All rights reserved.
//

import UIKit
import AVKit
import Photos
import NVActivityIndicatorView

final class MergeVideoViewController: UIViewController, NVActivityIndicatorViewable {
    
    private lazy var topVideoPlayer: VideoPlayer = {
        let url = Bundle.main.url(forResource: "video1", withExtension: "mp4")
        
        return VideoPlayer(url: url!)
    }()
    
    private lazy var bottomVideoPlayer: VideoPlayer = {
        let url = Bundle.main.url(forResource: "video2", withExtension: "mp4")
        
        return VideoPlayer(url: url!)
    }()
    
    private lazy var videoMerger: VideoMerger = {
        return VideoMerger(firstAsset: topVideoPlayer.asset, secondAsset: bottomVideoPlayer.asset)
    }()
    
    // MARK: Views
    
    @IBOutlet private weak var topVideoView: UIView?
    @IBOutlet private weak var bottomVideoView: UIView?
    
    @IBOutlet private weak var mergeVideoButton: UIButton?
    
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    
    // MARK: - UI
    // MARK: Configuration
    
    private func configureUI() {
        if let topVideoView = topVideoView {
            topVideoPlayer.attach(to: self, view: topVideoView)
        }
        
        if let bottomVideoView = bottomVideoView {
            bottomVideoPlayer.attach(to: self, view: bottomVideoView)
        }
    }
    
    // MARK: Actions
    
    @IBAction
    private func mergeVideoButtonTouchedUpInside(_ sender: UIButton) {
        mergeVideoButton?.isEnabled = false
        
        merge()
    }
    
    // MARK: - Appearance
    
    private func merge() {
        
        let size = CGSize(width: 30, height: 30)
        startAnimating(size, message: "", messageFont: nil, type: NVActivityIndicatorType.ballSpinFadeLoader, color: nil, padding: nil, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: nil, textColor: nil, fadeInAnimation: nil)
        videoMerger.merge { [weak self] session in
            
            self?.stopAnimating()
            
            guard let `self` = self else {
                return
            }
            
            self.mergeVideoButton?.isEnabled = true
            
            guard session.status == .completed,
                let outputURL = session.outputURL else { return }
    
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                PHPhotoLibrary.requestAuthorization({ status in
                    if status == .authorized {
                        self.saveVideo(url: outputURL)
                    }
                })
            } else {
                self.saveVideo(url: outputURL)
            }
        }
    }
    
    private func saveVideo(url: URL) {
        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }) { saved, error in
            let success = saved && (error == nil)
            let title = success ? "Success" : "Error"
            let message = success ? "Video saved" : "Failed to save video"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
