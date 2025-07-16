import SwiftUI
import UIKit

extension String {
    func heightForWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let attributedString = NSAttributedString(string: self, attributes: [.font: font])
        let rect = attributedString.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return ceil(rect.height)
    }
}