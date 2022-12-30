//
//  ViewController+Boxer.swift
//  VideoExportDemo
//
//  Created by Condy on 2022/12/30.
//

import Foundation
import AVKit
import VideoBox

extension ViewController {
    func boxer(at url: URL) {
        // Creating temp path to save the converted video
        let outputURL: URL = {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let outputURL = documentsDirectory.appendingPathComponent("condy_exporter_video.mp4")
            
            // Check if the file already exists then remove the previous file
            if FileManager.default.fileExists(atPath: outputURL.path) {
                do {
                    try FileManager.default.removeItem(at: outputURL)
                } catch {
                    //completionHandler(nil, error)
                }
            }
            return outputURL
        }()
        
        let commands: [Command] = [
            RotateCommand.init(angle: 180),
        ]
        
        let boxer = Boxer(videoURL: videoURL, commands: commands)
        boxer.outputVideo(outputURL) { [weak self] videoURL, error in
            guard let videoURL = videoURL else { return }
            let playerItem = AVPlayerItem(url: videoURL)
            let player = AVPlayer(playerItem: playerItem)
            self?.playerView.player = player
            player.play()
        }
    }
}
