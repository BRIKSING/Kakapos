//
//  ExporterError.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation

extension VideoExporter {
    public enum Error {
        case unknown
        case error(Swift.Error)
        case videoTrackEmpty
        case addVideoTrack
        case exportSessionEmpty
        case exportAsynchronously(AVAssetExportSession.Status)
    }
}

extension VideoExporter.Error {
    /// A textual representation of `self`, suitable for debugging.
    public var localizedDescription: String {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .videoTrackEmpty:
            return "Video track is nil."
        case .exportSessionEmpty:
            return "Video asset export session is nil."
        case .addVideoTrack:
            return "Add video mutable track is nil."
        case .exportAsynchronously(let status):
            return "export asynchronously other is \(status)."
        default:
            return "Unknown error occurred."
        }
    }
}
