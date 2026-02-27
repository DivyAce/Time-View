import Foundation
import UIKit

@MainActor
struct ImageCompressor {
    /// Compresses a raw image Data down to a max dimension (e.g., 256px) and 0.7 JPEG quality
    /// to prevent UserDefaults (AppStorage) from crashing with high-res photos.
    static func compress(data: Data, maxDimension: CGFloat = 256) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let size = image.size
        let maxSide = max(size.width, size.height)
        
        // If it's already small enough, just compress as JPEG
        guard maxSide > maxDimension else {
            return image.jpegData(compressionQuality: 0.7)
        }
        
        // Otherwise, scale it down
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // Use 1.0 scale to keep exact pixel dimensions
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}
