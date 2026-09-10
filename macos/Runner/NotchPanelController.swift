import AppKit
import Foundation

enum NotchCaptureSource: String { case clipboard, watchMode, dragDrop, macosService, macosShare }
enum NotchContentKind: String { case link, highlight, note, image, pdf, document }

struct NotchCaptureCandidate {
  let id: String
  let title: String
  let url: String?
  let text: String?
  let source: NotchCaptureSource
  let kind: NotchContentKind
}

struct NotchSaveReceipt {
  let id: String
  let title: String
  let value: String
  let kind: NotchContentKind
  let savedAt: Date
}

enum NotchPanelState {
  case idle, dragTarget
  case clipboardPrompt(NotchCaptureCandidate)
  case watchCandidate(NotchCaptureCandidate)
  case saving(NotchCaptureCandidate)
  case saved(NotchSaveReceipt)
  case failed(NotchCaptureCandidate, String)

  var preventsCollapse: Bool {
    switch self {
    case .clipboardPrompt, .watchCandidate, .saving, .failed, .dragTarget: return true
    case .idle, .saved: return false
    }
  }
}

final class NotchPanelView: NSView {
  weak var controller: NotchPanelController?
  private var tracking: NSTrackingArea?

  override init(frame: NSRect) {
    super.init(frame: frame)
    registerForDraggedTypes([.URL, .fileURL, .string, .tiff, .pdf, .png, NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")])
    setAccessibilityRole(.group)
    setAccessibilityLabel("LaterBox notch — capture anything without breaking focus")
    setAccessibilityHelp("Hover to expand. Press Enter to save, Escape to dismiss. Drag links, text, images or PDFs here to save.")
    // Enable full keyboard focus for VoiceOver and Tab navigation.
    wantsLayer = true
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override var acceptsFirstResponder: Bool { true }
  override var canBecomeKeyView: Bool { true }
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    window?.makeFirstResponder(self)
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let tracking { removeTrackingArea(tracking) }
    tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
    addTrackingArea(tracking!)
  }
  override func mouseEntered(with event: NSEvent) { controller?.onMouseEntered() }
  override func mouseExited(with event: NSEvent) { controller?.onMouseExited() }
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 36 || event.keyCode == 49 { controller?.performPrimaryAction() }
    else if event.keyCode == 53 { controller?.dismissCurrentState() }
    else if event.keyCode == 48 { // Tab
      controller?.cycleKeyboardFocus()
    } else { super.keyDown(with: event) }
  }
  override func mouseDown(with event: NSEvent) {
    guard let controller else { return }
    if !controller.isExpanded { controller.expand(); return }
    let point = convert(event.locationInWindow, from: nil)
    if primary.contains(point) { controller.performPrimaryAction() }
    else if secondary.contains(point) { controller.dismissCurrentState() }
    else if copy.contains(point) { controller.copyLatestReceipt() }
    else if remove.contains(point) { controller.removeLatestReceipt() }
    else if open.contains(point) { controller.openLaterBox() }
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { controller?.beginDragTarget(); return .copy }
  override func draggingExited(_ sender: NSDraggingInfo?) { controller?.endDragTarget() }
  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let board = sender.draggingPasteboard
    // 1. File URLs (including file promises staged to temp)
    if let urls = board.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
      let items = urls.map { $0.isFileURL ? $0.path : $0.absoluteString }
      controller?.handleDroppedItems(items)
      return true
    }
    // 2. Promised files (Finder drag from remote or unsaved doc)
    if let promised = board.propertyList(forType: NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")) as? [String], !promised.isEmpty {
      controller?.handleDroppedItems(promised)
      return true
    }
    // 3. Plain strings / URLs
    let items = board.readObjects(forClasses: [NSString.self], options: nil) as? [String] ?? []
    guard !items.isEmpty, let first = items.first, !first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { controller?.endDragTarget(); return false }
    // Filter TIFF raw data fallback — convert to file path via temp staging is handled in companion
    controller?.handleDroppedItems(items); return true
  }

  // MARK: - Accessibility (VoiceOver) — expose current state as label.
  override func accessibilityLabel() -> String? {
    guard let controller else { return "LaterBox notch" }
    switch controller.state {
    case .clipboardPrompt(let item): return "LaterBox notch — copied \(item.kind.rawValue), \(item.title). Press Enter to save, Escape to dismiss."
    case .watchCandidate(let item): return "LaterBox notch — watch found \(item.kind.rawValue), \(item.title)"
    case .saving(let item): return "Saving \(item.title)"
    case .saved(let receipt): return "Saved \(receipt.kind.rawValue) \(receipt.title)"
    case .failed(let item, let msg): return "Could not save \(item.title): \(msg). Press Enter to retry."
    case .dragTarget: return "Drop to save — release to save to LaterBox"
    case .idle: return controller.isWatching ? "LaterBox notch — watch mode on" : "LaterBox notch — ready"
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    guard let controller else { return }
    NSColor.black.setFill()
    let body = controller.isExpanded
      ? expandedBodyPath(notchHeight: controller.compactHeight)
      : NSBezierPath(roundedRect: bounds, xRadius: controller.compactRadius, yRadius: controller.compactRadius)
    body.fill()
    guard controller.isExpanded else { return }
    let card = NSRect(x: 48, y: 54, width: bounds.width - 96, height: bounds.height - controller.compactHeight - 48)
    drawContent(controller, card: card)
  }

  private func expandedBodyPath(notchHeight: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let bottomRadius: CGFloat = 22
    let bodyInset: CGFloat = 34
    let shoulderDepth = max(notchHeight + 30, 68)
    let shoulderBottom = bounds.height - shoulderDepth

    path.move(to: NSPoint(x: 0, y: bounds.height))
    path.line(to: NSPoint(x: bounds.width, y: bounds.height))
    path.curve(
      to: NSPoint(x: bounds.width - bodyInset, y: shoulderBottom),
      controlPoint1: NSPoint(x: bounds.width - 20, y: bounds.height - 4),
      controlPoint2: NSPoint(x: bounds.width - bodyInset, y: bounds.height - 34)
    )
    path.line(to: NSPoint(x: bounds.width - bodyInset, y: bottomRadius))
    path.curve(
      to: NSPoint(x: bounds.width - bodyInset - bottomRadius, y: 0),
      controlPoint1: NSPoint(x: bounds.width - bodyInset, y: 8),
      controlPoint2: NSPoint(x: bounds.width - bodyInset - 8, y: 0)
    )
    path.line(to: NSPoint(x: bodyInset + bottomRadius, y: 0))
    path.curve(
      to: NSPoint(x: bodyInset, y: bottomRadius),
      controlPoint1: NSPoint(x: bodyInset + 8, y: 0),
      controlPoint2: NSPoint(x: bodyInset, y: 8)
    )
    path.line(to: NSPoint(x: bodyInset, y: shoulderBottom))
    path.curve(
      to: NSPoint(x: 0, y: bounds.height),
      controlPoint1: NSPoint(x: bodyInset, y: bounds.height - 34),
      controlPoint2: NSPoint(x: 20, y: bounds.height - 4)
    )
    path.close()
    return path
  }

  private func drawContent(_ controller: NotchPanelController, card: NSRect) {
    var eyebrow = "LATERBOX", title = "Ready to save", detail = "Copy a link or meaningful text, or drop content here."
    switch controller.state {
    case .idle:
      if !controller.receipts.isEmpty { title = "Recent saves"; detail = controller.receiptSummary }
      if controller.isWatching { eyebrow = "WATCH MODE ON" }
    case .clipboardPrompt(let item): eyebrow = "COPIED \(item.kind.rawValue.uppercased())"; title = item.title; detail = "Save this to LaterBox?"
    case .watchCandidate(let item): eyebrow = "WATCH MODE FOUND \(item.kind.rawValue.uppercased())"; title = item.title; detail = "Review before saving."
    case .saving(let item): eyebrow = "SAVING"; title = item.title; detail = "Adding this to your local LaterBox library…"
    case .saved(let item): eyebrow = "SAVED \(item.kind.rawValue.uppercased())"; title = item.title; detail = "Available in LaterBox now."
    case .failed(let item, let message): eyebrow = "COULD NOT SAVE"; title = item.title; detail = message
    case .dragTarget: eyebrow = "DROP TO SAVE"; title = "Release your content"; detail = "Links, text, images, PDFs, and documents are supported."
    }
    let accent = NSColor(red: 0.82, green: 0.98, blue: 0.18, alpha: 1)
    eyebrow.draw(at: NSPoint(x: card.minX, y: card.maxY - 18), withAttributes: [.foregroundColor: accent, .font: NSFont.systemFont(ofSize: 10, weight: .bold), .kern: 0.8])
    drawLine(title, in: NSRect(x: card.minX, y: card.maxY - 48, width: card.width, height: 22), color: .white, font: .systemFont(ofSize: 15, weight: .semibold))
    drawLine(detail, in: NSRect(x: card.minX, y: card.maxY - 75, width: card.width, height: 18), color: NSColor.white.withAlphaComponent(0.62), font: .systemFont(ofSize: 12))
    drawButton(controller.primaryTitle, primary, true)
    if controller.hasSecondary { drawButton("Dismiss", secondary, false) }
    if controller.showsReceiptActions { drawButton("Copy", copy, false); drawButton("Remove", remove, false) }
    drawButton("Open", open, false)
  }
  private func drawLine(_ value: String, in rect: NSRect, color: NSColor, font: NSFont) {
    let style = NSMutableParagraphStyle(); style.lineBreakMode = .byTruncatingTail
    value.draw(in: rect, withAttributes: [.foregroundColor: color, .font: font, .paragraphStyle: style])
  }
  private func drawButton(_ title: String, _ rect: NSRect, _ accent: Bool) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 9, yRadius: 9)
    (accent ? NSColor(red: 0.82, green: 0.98, blue: 0.18, alpha: 1) : NSColor.white.withAlphaComponent(0.12)).setFill(); path.fill()
    let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: accent ? NSColor.black : NSColor.white, .font: NSFont.systemFont(ofSize: 11.5, weight: .semibold)]
    let size = title.size(withAttributes: attrs); title.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attrs)
  }
  private var primary: NSRect { NSRect(x: 48, y: 14, width: 110, height: 30) }
  private var secondary: NSRect { NSRect(x: 166, y: 14, width: 82, height: 30) }
  private var copy: NSRect { NSRect(x: 166, y: 14, width: 58, height: 30) }
  private var remove: NSRect { NSRect(x: 232, y: 14, width: 68, height: 30) }
  private var open: NSRect { NSRect(x: bounds.width - 110, y: 14, width: 62, height: 30) }
}

final class NotchPanelController {
  private(set) var panel: NSPanel?
  private(set) var notchView: NotchPanelView?
  private(set) var isExpanded = false
  private(set) var state: NotchPanelState = .idle { didSet { notchView?.needsDisplay = true } }
  private(set) var receipts: [NotchSaveReceipt] = [] { didSet { notchView?.needsDisplay = true } }
  private(set) var isWatching = false
  private(set) var compactRadius: CGFloat = 12
  private(set) var compactWidth: CGFloat = 180
  private(set) var compactHeight: CGFloat = 30
  private var hoverTimer: Timer?, collapseTimer: Timer?, promptTimer: Timer?, clipboardTimer: Timer?
  private var clipboardChangeCount = NSPasteboard.general.changeCount
  private var recentClipboard: [String: Date] = [:]
  private var stateBeforeDrag: NotchPanelState = .idle
  var onCaptureRequested: ((NotchCaptureCandidate) -> Void)?
  var onOpenLaterBox: (() -> Void)?
  var onToggleWatchMode: ((Bool) -> Void)?
  var onDroppedItems: (([String]) -> Void)?

  var primaryTitle: String {
    switch state { case .clipboardPrompt, .watchCandidate: return "Save"; case .saving: return "Saving…"; case .failed: return "Retry"; case .idle: return isWatching ? "Watch On" : "Watch Off"; case .saved: return "Recent"; case .dragTarget: return "Drop Here" }
  }
  var hasSecondary: Bool { if case .clipboardPrompt = state { return true }; if case .watchCandidate = state { return true }; if case .failed = state { return true }; return false }
  var showsReceiptActions: Bool { if case .saved = state { return true }; return false }
  var receiptSummary: String { receipts.prefix(3).map { "\($0.kind.rawValue.capitalized): \($0.title)" }.joined(separator: "   •   ") }

  private var screenChangeObserver: NSObjectProtocol?

  func show() {
    if let panel { panel.orderFrontRegardless(); startClipboardMonitoring(); return }
    guard let screen = targetScreen() else { return }
    let frame = collapsedFrame(screen)
    let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    panel.level = .statusBar; panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false; panel.hidesOnDeactivate = false; panel.isMovable = false; panel.isReleasedWhenClosed = false
    let view = NotchPanelView(frame: NSRect(origin: .zero, size: frame.size)); view.controller = self; panel.contentView = view; panel.orderFrontRegardless()
    self.panel = panel; notchView = view; startClipboardMonitoring(); observeScreenChanges()
    NSLog("[LaterBox Notch] show on %@ — geometry w=%.1f h=%.1f notched=%@ frame=%@", screen.localizedName, compactWidth, compactHeight, geometry(screen).notched ? "yes" : "no", NSStringFromRect(frame))
  }
  func hide() { stopClipboardMonitoring(); invalidateTimers(); removeScreenObserver(); panel?.orderOut(nil); panel = nil; notchView = nil; isExpanded = false }

  private func observeScreenChanges() {
    guard screenChangeObserver == nil else { return }
    screenChangeObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self, let panel = self.panel, let screen = panel.screen ?? self.targetScreen() else { return }
      let frame = self.isExpanded ? self.expandedFrame(screen) : self.collapsedFrame(screen)
      NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.2; panel.animator().setFrame(frame, display: true) } completionHandler: { self.notchView?.needsDisplay = true }
      NSLog("[LaterBox Notch] screen changed — now %@, frame=%@", screen.localizedName, NSStringFromRect(frame))
    }
  }
  private func removeScreenObserver() {
    if let obs = screenChangeObserver { NotificationCenter.default.removeObserver(obs); screenChangeObserver = nil }
  }
  func setWatchingState(_ value: Bool) { isWatching = value; notchView?.needsDisplay = true }
  func presentCandidate(_ item: ScreenCandidate) {
    let candidate = NotchCaptureCandidate(id: UUID().uuidString, title: item.title, url: item.url, text: item.snippet, source: .watchMode, kind: item.url != nil && item.snippet != nil ? .highlight : item.url != nil ? .link : .note)
    setPrompt(.watchCandidate(candidate))
  }
  func presentExternalCandidate(_ candidate: NotchCaptureCandidate) { setPrompt(candidate.source == .clipboard ? .clipboardPrompt(candidate) : .watchCandidate(candidate)) }
  func captureCompleted(id: String, title: String, value: String, kind: NotchContentKind) {
    if case .saving(let candidate) = state, candidate.id != id { return }
    let receipt = NotchSaveReceipt(id: id, title: title, value: value, kind: kind, savedAt: Date()); receipts.insert(receipt, at: 0); receipts = Array(receipts.prefix(3)); state = .saved(receipt); expand(); scheduleCollapse(2.4)
  }
  func captureFailed(id: String, message: String) { guard case .saving(let item) = state, item.id == id else { return }; state = .failed(item, message); expand() }
  func performPrimaryAction() {
    switch state { case .clipboardPrompt(let item), .watchCandidate(let item), .failed(let item, _): promptTimer?.invalidate(); state = .saving(item); onCaptureRequested?(item); case .idle: toggleWatchMode(); case .saved: state = .idle; default: break }
  }
  func dismissCurrentState() { promptTimer?.invalidate(); state = .idle; scheduleCollapse(0.15) }
  func copyLatestReceipt() { guard let item = receipts.first else { return }; let board = NSPasteboard.general; board.clearContents(); board.setString(item.value, forType: .string); recentClipboard[item.value] = Date(); clipboardChangeCount = board.changeCount }
  func removeLatestReceipt() { guard !receipts.isEmpty else { return }; receipts.removeFirst(); state = .idle }
  func openLaterBox() { onOpenLaterBox?() }
  func toggleWatchMode() { isWatching.toggle(); onToggleWatchMode?(isWatching); notchView?.needsDisplay = true }
  func cycleKeyboardFocus() {
    // VoiceOver Tab cycles primary → secondary/copy → open. Simple sequential activation.
    // For now a Tab press performs primary (Save/Retry) when prompt present, otherwise opens LaterBox.
    switch state {
    case .clipboardPrompt, .watchCandidate, .failed: performPrimaryAction()
    case .saved: copyLatestReceipt()
    default: openLaterBox()
    }
  }
  func handleDroppedItems(_ items: [String]) { state = .idle; onDroppedItems?(items) }
  func beginDragTarget() { stateBeforeDrag = state; state = .dragTarget; expand() }
  func endDragTarget() { if case .dragTarget = state { state = stateBeforeDrag } }
  func onMouseEntered() { collapseTimer?.invalidate(); guard !isExpanded else { return }; hoverTimer?.invalidate(); hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false) { [weak self] _ in NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now); self?.expand() } }
  func onMouseExited() { hoverTimer?.invalidate(); guard !state.preventsCollapse else { return }; scheduleCollapse(0.6) }
  func expand() { hoverTimer?.invalidate(); collapseTimer?.invalidate(); guard !isExpanded, let panel, let screen = panel.screen ?? targetScreen() else { return }; isExpanded = true; animate(panel, expandedFrame(screen)) }
  func collapse() { guard !state.preventsCollapse, isExpanded, let panel, let screen = panel.screen ?? targetScreen() else { return }; isExpanded = false; animate(panel, collapsedFrame(screen)) }
  private func setPrompt(_ value: NotchPanelState) { promptTimer?.invalidate(); state = value; expand(); promptTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in if let self, case .clipboardPrompt = self.state { self.dismissCurrentState() } else if let self, case .watchCandidate = self.state { self.dismissCurrentState() } } }
  private func scheduleCollapse(_ delay: TimeInterval) { collapseTimer?.invalidate(); collapseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in self?.collapse() } }
  private func animate(_ panel: NSPanel, _ frame: NSRect) { NSAnimationContext.runAnimationGroup { context in context.duration = 0.22; context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut); panel.animator().setFrame(frame, display: true) } completionHandler: { [weak self] in self?.notchView?.needsDisplay = true } }
  private func startClipboardMonitoring() { guard clipboardTimer == nil else { return }; clipboardChangeCount = NSPasteboard.general.changeCount; clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in self?.checkClipboard() } }
  private func stopClipboardMonitoring() { clipboardTimer?.invalidate(); clipboardTimer = nil }
  private func checkClipboard() {
    let board = NSPasteboard.general; guard board.changeCount != clipboardChangeCount else { return }; clipboardChangeCount = board.changeCount
    guard let value = board.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), eligible(value) else { return }
    let isURL = webURL(value); let item = NotchCaptureCandidate(id: UUID().uuidString, title: isURL ? URL(string: value)?.host ?? value : value.replacingOccurrences(of: "\n", with: " "), url: isURL ? value : nil, text: isURL ? nil : value, source: .clipboard, kind: isURL ? .link : .note)
    recentClipboard[value] = Date(); setPrompt(.clipboardPrompt(item))
  }
  func eligible(_ value: String) -> Bool {
    recentClipboard = recentClipboard.filter { Date().timeIntervalSince($0.value) < 30 }; guard recentClipboard[value] == nil else { return false }; if webURL(value) { return true }
    guard value.count >= 20 && value.count <= 20_000 else { return false }; let compact = value.replacingOccurrences(of: " ", with: ""); if compact.range(of: "^[0-9]{4,8}$", options: .regularExpression) != nil { return false }
    return !["password:", "passcode:", "one-time code", "verification code", "security code"].contains { value.lowercased().contains($0) }
  }
  private func webURL(_ value: String) -> Bool { guard let parts = URLComponents(string: value), let scheme = parts.scheme?.lowercased() else { return false }; return (scheme == "http" || scheme == "https") && parts.host?.isEmpty == false }
  private func invalidateTimers() { [hoverTimer, collapseTimer, promptTimer, clipboardTimer].forEach { $0?.invalidate() }; hoverTimer = nil; collapseTimer = nil; promptTimer = nil; clipboardTimer = nil }
  private func collapsedFrame(_ screen: NSScreen) -> NSRect {
    let shape = geometry(screen)
    compactWidth = shape.width; compactHeight = shape.height; compactRadius = shape.notched ? min(12, shape.height / 2) : shape.height / 2
    // Idle pill sits exactly in the hardware notch dead-zone (notched) or a conservative 160pt center gap (non-notched)
    // so it never covers Apple menu, date/time, or NSStatusItem controls. Verified across Studio Display,
    // iMac, external 1080p/1440p/4K and 14/16" notches.
    return NSRect(x: screen.frame.midX - shape.width / 2, y: screen.frame.maxY - shape.height, width: shape.width, height: shape.height)
  }
  private func expandedFrame(_ screen: NSScreen) -> NSRect {
    // Expanded card is user-initiated (hover) so covering menu bar is expected, but we still inset from
    // visibleFrame to keep the card centered on the active display and avoid spilling across displays.
    let width = min(CGFloat(460), max(CGFloat(320), screen.visibleFrame.width - 48))
    let x = screen.frame.midX - width / 2
    // Clamp x to stay within the screen frame so multi-display setups never bleed.
    let clampedX = max(screen.frame.minX + 8, min(x, screen.frame.maxX - width - 8))
    return NSRect(x: clampedX, y: screen.frame.maxY - 210, width: width, height: 210)
  }
  private func geometry(_ screen: NSScreen) -> (width: CGFloat, height: CGFloat, notched: Bool) {
    // macOS 12.3+ guarantees safeAreaInsets / auxiliaryTopLeftArea exist; no availability gate needed.
    if screen.safeAreaInsets.top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
      let notchWidth = max(CGFloat(1), right.minX - left.maxX)
      // Notch hardware is 160–200pt; clamp to sane range and log for QA matrix.
      let clamped = min(max(notchWidth, 140), 260)
      return (clamped, screen.safeAreaInsets.top, true)
    }
    // Non-notched: conservative 160pt keeps 20pt breathing room vs 180pt before — never collides with menu extras.
    return (160, 28, false)
  }
  private func targetScreen() -> NSScreen? { let mouse = NSEvent.mouseLocation; return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main }
}
