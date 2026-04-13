import Foundation

@MainActor
final class AudioPlayerService {
    private(set) var currentTrackID: String?

    func preload(trackID: String) {
        currentTrackID = trackID
    }
}
