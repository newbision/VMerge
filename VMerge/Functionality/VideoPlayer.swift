//
//  VideoPlayer.swift
//  VMerge
//
//  Created by Sb15utah on 8/22/18.
//  Copyright © 2018. All rights reserved.
//

import Foundation
import AVKit

final class VideoPlayer: NSObject {
    
    // MARK: - Properties
    
    var player = AVPlayer()
    var playerController = AVPlayerViewController()
    
    private(set) var url: URL
    
    lazy var asset: AVURLAsset = {
        return AVURLAsset(url: url)
    }()
    
    // MARK: - Initialization
    
    init(url: URL) {
        self.url = url
    }
    
    // MARK: - Appearance
    
    func attach(to viewController: UIViewController,
                view: UIView) {
        player = AVPlayer(url: url)
        
        let playerController = AVPlayerViewController()
        playerController.player = player
        viewController.addChildViewController(playerController)
        
        playerController.view.translatesAutoresizingMaskIntoConstraints = false
        playerController.view.frame = view.frame
        view.addSubview(playerController.view)
        
        playerController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        playerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
}
