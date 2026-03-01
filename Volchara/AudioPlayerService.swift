import AVFoundation
import Foundation

final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    private var players: [AVAudioPlayer] = []

    func play(url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            players.append(player)
        } catch {
            print("volchara: failed to play \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        players.removeAll { $0 === player }
    }
}
