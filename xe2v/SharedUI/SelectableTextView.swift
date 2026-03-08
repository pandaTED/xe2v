import SwiftUI
import UIKit

struct SelectableTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> Base64SelectableTextView {
        let textView = Base64SelectableTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link]
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: Base64SelectableTextView, context: Context) {
        uiView.attributedText = attributedText
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let decodeAction = UIAction(title: "Base64 解码并复制") { _ in
                guard let custom = textView as? Base64SelectableTextView else { return }
                custom.decodeSelectedBase64AndCopy(range: range)
            }
            return UIMenu(children: suggestedActions + [decodeAction])
        }
    }
}

final class Base64SelectableTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }

    func decodeSelectedBase64AndCopy(range: NSRange) {
        let selected = (text as NSString).substring(with: range)
        guard let output = selected.decodedBase64String else { return }
        UIPasteboard.general.string = output
        DebugLog.info("base64 decoded and copied length=\(output.count)", category: "TextSelect")
    }
}

private extension String {
    var decodedBase64String: String? {
        let compact = self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        guard !compact.isEmpty else { return nil }

        let pad = compact.count % 4
        let normalized = pad == 0 ? compact : compact + String(repeating: "=", count: 4 - pad)
        guard let data = Data(base64Encoded: normalized) else { return nil }

        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        return data.map { String(format: "%02x", $0) }.joined()
    }
}
