import Foundation

@MainActor
final class AudioPlayerService {
    private(set) var currentTrackID: String?
    private(set) var currentAssetName: String?

    func preload(trackID: String) {
        currentTrackID = trackID
        currentAssetName = (UserPreferences.AudioTrack(rawValue: trackID) ?? .fallback).bundledFileName
    }
}
