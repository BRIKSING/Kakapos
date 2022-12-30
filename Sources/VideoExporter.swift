//
//  VideoExporter.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation
import CoreVideo

public typealias ExporterBuffer = CVPixelBuffer

public struct VideoExporter {
    
    public typealias PixelBufferCallback = (_ buffer: ExporterBuffer) -> ExporterBuffer?
    
    let asset: AVAsset
    weak var delegate: ExporterDelegate?
    
    public var presetName: String = AVAssetExportPresetHighestQuality {
        didSet {
            if !AVAssetExportSession.allExportPresets().contains(presetName) {
                presetName = AVAssetExportPresetMediumQuality
            }
        }
    }
    
    public init(videoURL: URL, delegate: ExporterDelegate) {
        self.init(asset: AVAsset(url: videoURL), delegate: delegate)
    }
    
    public init(asset: AVAsset, delegate: ExporterDelegate) {
        self.asset = asset
        self.delegate = delegate
    }
    
    /// Export the video after injecting the filter.
    /// - Parameters:
    ///   - outputURL: Specifies the sandbox address of the exported video.
    ///   - optimizeForNetworkUse: Indicates that the output file should be optimized for network use.
    ///   - filtering: Filters work to filter pixel buffer.
    public func export(outputURL: URL, optimizeForNetworkUse: Bool = true, filtering: @escaping PixelBufferCallback) {
        guard let track = self.asset.tracks(withMediaType: .video).first else {
            delegate?.export(self, failed: VideoExporter.Error.videoTrackEmpty)
            return
        }
        
        let composition = AVMutableComposition()
        composition.naturalSize = track.naturalSize
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            delegate?.export(self, failed: VideoExporter.Error.addVideoTrack)
            return
        }
        
        do {
            try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.asset.duration), of: track, at: .zero)
        } catch {
            delegate?.export(self, failed: VideoExporter.Error.error(error))
        }
        
        var audioTrack: AVMutableCompositionTrack? = nil
        if let audio = self.asset.tracks(withMediaType: .audio).first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            audioTrack = audioCompositionTrack
            do {
                try audioTrack!.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.asset.duration), of: audio, at: .zero)
            } catch {
                delegate?.export(self, failed: VideoExporter.Error.error(error))
            }
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.trackID = videoTrack.trackID
        
        let instruction = CompositionInstruction(trackID: videoTrack.trackID, bufferCallback: filtering)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: self.asset.duration)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = Compositor.self
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.instructions = [instruction]
        
        guard let export = AVAssetExportSession(asset: composition, presetName: presetName) else {
            delegate?.export(self, failed: VideoExporter.Error.exportSessionEmpty)
            return
        }
        export.videoComposition = videoComposition
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = optimizeForNetworkUse
        
        export.exportAsynchronously { [weak export] in
            guard let export = export else { return }
            DispatchQueue.main.async {
                switch export.status {
                case .failed:
                    if let error = export.error {
                        delegate?.export(self, failed: VideoExporter.Error.error(error))
                    } else {
                        delegate?.export(self, failed: VideoExporter.Error.unknown)
                    }
                case .completed:
                    delegate?.export(self, success: outputURL)
                default:
                    delegate?.export(self, failed: VideoExporter.Error.exportAsynchronously(export.status))
                    break
                }
            }
        }
    }
}
