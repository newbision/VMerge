//
//  VideoMerger.swift
//  VMerge
//
//  Created by newbision on 8/22/18.
//  Copyright © 2018 AK. All rights reserved.
//

import Foundation
import AVKit
import MobileCoreServices
import MediaPlayer

final class VideoMerger {
    
    // MARK: - Properties
    
    private var firstAsset: AVURLAsset
    private var secondAsset: AVURLAsset
    
    private lazy var isPortrait: Bool = {
        guard let firstTransform = firstAsset.tracks.first?.preferredTransform,
            let secondTransform = secondAsset.tracks.first?.preferredTransform else {
                return false
        }
        
        return orientationFromTransform(firstTransform).isPortrait &&
            orientationFromTransform(secondTransform).isPortrait
    }()
    
    private lazy var videoSize: CGSize = {
        guard let firstAssetSize = firstAsset.tracks.first?.naturalSize,
            let secondAssetSize = secondAsset.tracks.first?.naturalSize else {
                return .zero
        }

        if isPortrait {
            return CGSize(width: firstAssetSize.width + secondAssetSize.width, height: max(firstAssetSize.height, secondAssetSize.height))
        }
        
        return CGSize(width: max(firstAssetSize.width, secondAssetSize.width), height: firstAssetSize.height + secondAssetSize.height)
    }()
    
    private lazy var preferredSize: CGSize = {
        guard let firstTrack = firstAsset.tracks.first,
            let secondTrack = secondAsset.tracks.first else {
                return CGSize(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
        }
        
        let firstTrackSize = firstTrack.naturalSize
        let secondTrackSize = secondTrack.naturalSize
        
        if isPortrait && firstTrackSize.width > secondTrackSize.width {
            return firstTrackSize
        }
        
        if isPortrait && firstTrackSize.height > secondTrackSize.height {
            return firstTrackSize
        }
        
        return secondTrackSize
    }()
    
    
    // MARK: - Initialization
    
    init(firstAsset: AVURLAsset,
         secondAsset: AVURLAsset) {
        self.firstAsset = firstAsset
        self.secondAsset = secondAsset
    }
    
    
    // MARK: - Appearance
    
    typealias MergeCompletion = (AVAssetExportSession) -> Void
    func merge(completion: MergeCompletion?) {
        let mixComposition = AVMutableComposition()
        
        guard let firstTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }

        do {
            try firstTrack.insertTimeRange(
                CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                of: firstAsset.tracks(withMediaType: .video)[0],
                at: CMTime.zero
            )
        } catch {
            return
        }
        
        guard let secondTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        
        do {
            try secondTrack.insertTimeRange(
                CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration),
                of: secondAsset.tracks(withMediaType: .video)[0],
                at: CMTime.zero
            )
        } catch {
            return
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(
            start: CMTime.zero,
            duration: max(firstAsset.duration, secondAsset.duration)
        )
        
        let firstInstruction = videoCompositionInstruction(
            firstTrack,
            asset: firstAsset
        )
        
        firstInstruction.setOpacity(0.0, at: firstAsset.duration)
        
        let secondInstruction = videoCompositionInstruction(
            secondTrack,
            asset: secondAsset
        )
        
        secondInstruction.setOpacity(0.0, at: secondAsset.duration)
        
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = videoSize
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergedVideo-\(date).mov")
        
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        
        exporter.outputURL = url
        exporter.outputFileType = .mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                completion?(exporter)
            }
        }
    }
    
    
    // MARK: - Helpers
    
    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation: UIImage.Orientation = .up
        var isPortrait = false
        
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstruction(_ track: AVCompositionTrack,
                                     asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)

        var scaleToFitRatio = preferredSize.width / assetTrack.naturalSize.width

        if assetInfo.isPortrait {
            scaleToFitRatio = preferredSize.width / assetTrack.naturalSize.height

            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor), at: CMTime.zero)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor)

            if assetTrack.naturalSize.height < preferredSize.height {
                let difference = preferredSize.height - assetTrack.naturalSize.height
                concat = concat.concatenating(CGAffineTransform(translationX: 0, y: difference / 2.0))
            }

            if assetTrack.naturalSize.width < preferredSize.width {
                let difference = preferredSize.width - assetTrack.naturalSize.width
                concat = concat.concatenating(CGAffineTransform(translationX: difference / 2.0, y: 0))
            }

            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = preferredSize
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }

            instruction.setTransform(concat, at: CMTime.zero)
        }
        
        let isFirstVideo = asset == firstAsset
        var concat = assetTrack.preferredTransform
        
        if isPortrait {
//            [] []
            if isFirstVideo {
                concat = concat.concatenating(CGAffineTransform(translationX: 0, y: 0))
            } else {
                concat = concat.concatenating(CGAffineTransform(translationX: firstAsset.tracks[0].naturalSize.width, y: 0))
            }
        } else {
//            []
//            []
            if isFirstVideo {
                concat = concat.concatenating(CGAffineTransform(translationX: 0, y: 0))
            } else {
                concat = concat.concatenating(CGAffineTransform(translationX: 0, y: firstAsset.tracks[0].naturalSize.height))
            }
        }
        
        instruction.setTransform(concat, at: CMTime.zero)
        
        return instruction
    }
}
