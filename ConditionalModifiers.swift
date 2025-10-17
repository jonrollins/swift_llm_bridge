import SwiftUI

extension View {
    @ViewBuilder
    func ifAvailableScrollAnchor<T: View>(_ transform: (Self) -> T) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            transform(self)
        } else {
            self
        }
    }
}
