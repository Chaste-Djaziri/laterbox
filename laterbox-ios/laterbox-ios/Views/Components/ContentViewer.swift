//
//  ContentViewer.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import WebKit

// MARK: - Content Format Mode

public enum ContentFormatMode: String, CaseIterable, Identifiable {
    case formatted = "Formatted"
    case html = "HTML"
    case raw = "Raw"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .formatted: return "text.badge.checkmark"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .raw: return "text.alignleft"
        }
    }
}

// MARK: - HTML Content View

public struct HTMLContentView: UIViewRepresentable {
    public let html: String
    @Binding public var calculatedHeight: CGFloat

    public init(html: String, calculatedHeight: Binding<CGFloat>? = nil) {
        self.html = html
        self._calculatedHeight = calculatedHeight ?? .constant(300)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let styled = wrapHTML(html)
        uiView.loadHTMLString(styled, baseURL: nil)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLContentView

        init(_ parent: HTMLContentView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight || document.body.scrollHeight") { [weak self] result, _ in
                if let height = result as? CGFloat, height > 20 {
                    DispatchQueue.main.async {
                        self?.parent.calculatedHeight = max(height + 24, 100)
                    }
                }
            }
        }
    }

    private func wrapHTML(_ content: String) -> String {
        let isCompleteDoc = content.lowercased().contains("<html") || content.lowercased().contains("<!doctype")
        if isCompleteDoc { return content }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            :root {
                color-scheme: light dark;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                font-size: 15px;
                line-height: 1.6;
                color: #FFFFFF;
                background-color: transparent;
                margin: 0;
                padding: 4px;
                word-wrap: break-word;
                overflow-wrap: break-word;
            }
            @media (prefers-color-scheme: light) {
                body { color: #111827; }
                pre, code { background: rgba(0, 0, 0, 0.06); }
                blockquote { color: rgba(17, 24, 39, 0.75); }
                th, td { border-color: rgba(0, 0, 0, 0.12); }
            }
            h1, h2, h3, h4, h5, h6 {
                margin-top: 14px;
                margin-bottom: 8px;
                font-weight: 700;
                line-height: 1.3;
            }
            h1 { font-size: 1.35em; }
            h2 { font-size: 1.2em; }
            h3 { font-size: 1.05em; }
            p { margin: 6px 0 10px 0; }
            a { color: #10B981; text-decoration: underline; }
            img { max-width: 100%; height: auto; border-radius: 10px; margin: 8px 0; }
            pre, code {
                background: rgba(255, 255, 255, 0.08);
                padding: 2px 6px;
                border-radius: 6px;
                font-family: ui-monospace, Menlo, Monaco, monospace;
                font-size: 13px;
            }
            pre { padding: 12px; overflow-x: auto; margin: 10px 0; }
            blockquote {
                border-left: 3.5px solid #10B981;
                margin-left: 0;
                padding-left: 12px;
                color: rgba(255, 255, 255, 0.75);
                font-style: italic;
            }
            ul, ol { padding-left: 20px; margin: 6px 0 10px 0; }
            li { margin-bottom: 4px; }
            table { width: 100%; border-collapse: collapse; margin: 10px 0; }
            th, td { border: 1px solid rgba(255,255,255,0.15); padding: 6px 10px; }
        </style>
        </head>
        <body>
        \(content)
        </body>
        </html>
        """
    }
}

// MARK: - Markdown Content View

public struct MarkdownContentView: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(text))
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(4)
                .textSelection(.enabled)
                .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Rich Content Viewer Card (For Captured Text & Articles)

public struct RichCapturedContentViewer: View {
    public let title: String
    public let content: String
    public let formattedHTML: String?

    @State private var mode: ContentFormatMode = .formatted
    @State private var htmlHeight: CGFloat = 200
    @State private var isExpanded: Bool = false
    @State private var showingFullscreenReader: Bool = false
    @State private var copiedToast: Bool = false

    public init(title: String = "Captured Content", content: String, formattedHTML: String? = nil) {
        self.title = title
        self.content = content
        self.formattedHTML = formattedHTML
    }

    private var activeHTMLContent: String {
        if let formattedHTML, !formattedHTML.isEmpty {
            return formattedHTML
        }
        // If content itself looks like HTML
        if content.contains("<p>") || content.contains("<div") || content.contains("<h") {
            return content
        }
        return "<p>\(content.replacingOccurrences(of: "\n", with: "<br>"))</p>"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with format segmented toggle & utility actions
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.6)
                }

                Spacer()

                // Mode Picker
                HStack(spacing: 2) {
                    ForEach(ContentFormatMode.allCases) { m in
                        Button(action: {
                            LBHaptic.light()
                            mode = m
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: m.icon)
                                    .font(.system(size: 10, weight: .bold))
                                Text(m.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                mode == m ? Capsule().fill(AppTheme.accent) : Capsule().fill(Color.clear)
                            )
                            .foregroundColor(mode == m ? AppTheme.textPrimary : AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Capsule().fill(AppTheme.background))
                .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
            }

            // Top action buttons: Copy & Fullscreen Reader
            HStack(spacing: 8) {
                Button(action: {
                    UIPasteboard.general.string = content
                    LBHaptic.success()
                    withAnimation {
                        copiedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { copiedToast = false }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copiedToast ? "checkmark" : "doc.on.doc")
                            .font(.caption2.weight(.bold))
                        Text(copiedToast ? "Copied" : "Copy")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(copiedToast ? AppTheme.accent : AppTheme.background))
                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    .foregroundColor(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    showingFullscreenReader = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2.weight(.bold))
                        Text("Fullscreen Reader")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppTheme.background))
                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    .foregroundColor(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Main Content Area
            Group {
                switch mode {
                case .formatted:
                    MarkdownContentView(text: content)
                        .frame(maxHeight: isExpanded ? .infinity : 280, alignment: .topLeading)
                        .clipped()

                case .html:
                    HTMLContentView(html: activeHTMLContent, calculatedHeight: $htmlHeight)
                        .frame(height: isExpanded ? max(htmlHeight, 280) : min(htmlHeight, 280))
                        .clipped()

                case .raw:
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(content)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                            .textSelection(.enabled)
                            .padding(10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.background)
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                    )
                    .frame(maxHeight: isExpanded ? .infinity : 260)
                }
            }

            // Expand / Collapse Toggle if content is substantial
            if content.count > 300 || htmlHeight > 280 {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(.caption.weight(.bold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18)
        .sheet(isPresented: $showingFullscreenReader) {
            FullscreenContentReader(title: title, content: content, htmlContent: activeHTMLContent)
        }
    }
}

// MARK: - Fullscreen Content Reader Sheet

public struct FullscreenContentReader: View {
    @Environment(\.dismiss) private var dismiss
    public let title: String
    public let content: String
    public let htmlContent: String

    @State private var mode: ContentFormatMode = .formatted
    @State private var htmlHeight: CGFloat = 800

    public init(title: String, content: String, htmlContent: String) {
        self.title = title
        self.content = content
        self.htmlContent = htmlContent
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch mode {
                        case .formatted:
                            MarkdownContentView(text: content)
                                .padding(20)
                        case .html:
                            HTMLContentView(html: htmlContent, calculatedHeight: $htmlHeight)
                                .frame(minHeight: max(htmlHeight, 500))
                                .padding(16)
                        case .raw:
                            Text(content)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .foregroundColor(AppTheme.textPrimary)
                                .textSelection(.enabled)
                                .padding(20)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Format", selection: $mode) {
                        ForEach(ContentFormatMode.allCases) { m in
                            Label(m.rawValue, systemImage: m.icon).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Rich Notes Card (With Markdown & HTML Live Preview)

public struct RichNotesCard: View {
    @Binding public var text: String
    public let onSave: () -> Void

    @State private var mode: ContentFormatMode = .raw

    public init(text: Binding<String>, onSave: @escaping () -> Void) {
        self._text = text
        self.onSave = onSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.line")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("PERSONAL NOTES")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.6)
                }

                Spacer()

                // Mode toggle between Edit / Markdown Preview / HTML Preview
                HStack(spacing: 2) {
                    ForEach([ContentFormatMode.raw, ContentFormatMode.formatted, ContentFormatMode.html]) { m in
                        Button(action: {
                            LBHaptic.light()
                            mode = m
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: m == .raw ? "pencil" : m.icon)
                                    .font(.system(size: 10, weight: .bold))
                                Text(m == .raw ? "Edit" : m.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                mode == m ? Capsule().fill(AppTheme.accent) : Capsule().fill(Color.clear)
                            )
                            .foregroundColor(mode == m ? AppTheme.textPrimary : AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Capsule().fill(AppTheme.background))
                .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
            }

            // Quick Markdown helpers when in Edit mode
            if mode == .raw {
                HStack(spacing: 6) {
                    markdownInsertButton(label: "H1", insert: "# ")
                    markdownInsertButton(label: "H2", insert: "## ")
                    markdownInsertButton(label: "Bold", insert: "**text**")
                    markdownInsertButton(label: "List", insert: "- ")
                    markdownInsertButton(label: "Check", insert: "- [ ] ")
                    markdownInsertButton(label: "Code", insert: "`code`")
                    markdownInsertButton(label: "Quote", insert: "> ")
                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Content Area based on mode
            ZStack(alignment: .topLeading) {
                switch mode {
                case .raw:
                    if text.isEmpty {
                        Text("Add personal thoughts, markdown notes, takeaways, or reminders...")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $text)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 120)
                        .onChange(of: text) { _, _ in
                            onSave()
                        }

                case .formatted:
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No notes to preview yet. Switch to Edit to write notes in Markdown.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        MarkdownContentView(text: text)
                            .padding(14)
                            .frame(minHeight: 100, alignment: .topLeading)
                    }

                case .html:
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No HTML notes to render yet.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HTMLContentView(html: text)
                            .frame(minHeight: 120)
                            .padding(10)
                    }
                }
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func markdownInsertButton(label: String, insert: String) -> some View {
        Button(action: {
            LBHaptic.light()
            if text.isEmpty || text.hasSuffix("\n") {
                text += insert
            } else {
                text += "\n" + insert
            }
            onSave()
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(AppTheme.background))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                .foregroundColor(AppTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
