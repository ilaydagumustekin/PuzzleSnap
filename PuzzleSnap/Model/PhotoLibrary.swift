import UIKit

/// A bundled puzzle photo (`Photos/photo-<id>.jpg`, 1080×1440, Unsplash License via picsum.photos).
struct Photo: Hashable {
    let id: Int
    let title: String
}

enum PhotoLibrary {
    /// Width / height of every bundled photo.
    static let aspect: CGFloat = 3.0 / 4.0

    /// Level order: early levels get bold, varied pictures; subtler ones come later.
    static let all: [Photo] = [
        Photo(id: 696, title: "Laleler"),
        Photo(id: 593, title: "Kaplan"),
        Photo(id: 870, title: "Deniz Feneri"),
        Photo(id: 829, title: "Kızıl Kayalar"),
        Photo(id: 670, title: "İstiklal Tramvayı"),
        Photo(id: 433, title: "Boz Ayı"),
        Photo(id: 509, title: "Şelale"),
        Photo(id: 976, title: "Lale Bahçesi"),
        Photo(id: 1040, title: "Masal Şatosu"),
        Photo(id: 791, title: "Balon Vadisi"),
        Photo(id: 659, title: "Kurt Köpeği"),
        Photo(id: 901, title: "Kuzey Işıkları"),
        Photo(id: 564, title: "Kanyon"),
        Photo(id: 429, title: "Ahududu"),
        Photo(id: 1016, title: "Kızıl Tepeler"),
        Photo(id: 873, title: "Dağ Gölü"),
        Photo(id: 1025, title: "Battaniyeli Pug"),
        Photo(id: 645, title: "Palmiyeler"),
        Photo(id: 923, title: "Sisli Orman"),
        Photo(id: 1074, title: "Dişi Aslan"),
        Photo(id: 849, title: "Sahil Yolu"),
        Photo(id: 701, title: "Mavi Çiçekler"),
        Photo(id: 1043, title: "Vadi"),
        Photo(id: 553, title: "Sonbahar Bankları"),
        Photo(id: 639, title: "Dönme Dolap"),
        Photo(id: 582, title: "Çakal"),
        Photo(id: 1015, title: "Fiyort"),
        Photo(id: 828, title: "Havai Fişek"),
        Photo(id: 517, title: "Portakal Ağacı"),
        Photo(id: 871, title: "Gizli Koy"),
        Photo(id: 718, title: "Kurt"),
        Photo(id: 906, title: "Karlı Zirve"),
        Photo(id: 902, title: "Bulutların Üstü"),
        Photo(id: 1039, title: "Yeşil Şelale"),
        Photo(id: 674, title: "Üzüm"),
        Photo(id: 1003, title: "Yavru Geyik"),
        Photo(id: 864, title: "Şehir Manzarası"),
        Photo(id: 980, title: "Yansıma"),
        Photo(id: 937, title: "Kutup Ayısı"),
        Photo(id: 1084, title: "Morslar"),
        Photo(id: 360, title: "Turuncu Çiçekler"),
        Photo(id: 857, title: "Gece Işıkları"),
        Photo(id: 1069, title: "Denizanası"),
        Photo(id: 903, title: "Samanyolu"),
        Photo(id: 924, title: "Renkli Orman"),
        Photo(id: 1080, title: "Çilekler"),
        Photo(id: 1050, title: "Lagün"),
        Photo(id: 174, title: "Sıcak Hava Balonu"),
        Photo(id: 419, title: "Lizbon Tramvayı"),
        Photo(id: 896, title: "Gün Batımı"),
    ]

    static func photo(id: Int) -> Photo? { all.first { $0.id == id } }

    private static let cache = NSCache<NSString, UIImage>()

    /// The photo at full size (`width == nil`) or downscaled for thumbnails.
    static func image(for photo: Photo, width: CGFloat? = nil) -> UIImage {
        let key = "\(photo.id)@\(Int(width ?? 0))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let url = Bundle.main.url(forResource: "photo-\(photo.id)", withExtension: "jpg"),
              let full = UIImage(contentsOfFile: url.path) else { return UIImage() }
        var image = full
        if let width, width < full.size.width {
            let size = CGSize(width: width, height: (width / aspect).rounded())
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            image = UIGraphicsImageRenderer(size: size, format: format).image { _ in full.draw(in: CGRect(origin: .zero, size: size)) }
        }
        cache.setObject(image, forKey: key)
        return image
    }
}
