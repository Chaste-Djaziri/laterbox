import AppKit
import Foundation

/// Custom NSView for the macOS camera notch floating Dynamic Island.
/// Supports hover expansion, live candidate prompts, and direct drag-and-drop captures.
final class NotchPanelView: NSView {
  weak var controller: NotchPanelController?
  private var trackingArea: NSTrackingArea?

  var isHovered: Bool = false {
    didSet { needsDisplay = true }
  }
  var isDragTarget: Bool = false {
    didSet { needsDisplay = true }
  }

  // Active candidate detected by Watch Mode
  var currentCandidate: ScreenCandidate? {
    didSet { needsDisplay = true }
  }

  var isWatching: Bool = false {
    didSet { needsDisplay = true }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    registerForDraggedTypes([.URL, .fileURL, .string, .tiff])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    registerForDraggedTypes([.URL, .fileURL, .string, .tiff])
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea = trackingArea {
      removeTrackingArea(trackingArea)
    }
    let area = NSTrackingArea(
      rect: bounds,
      options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(area)
    self.trackingArea = area
  }

  override func mouseEntered(with event: NSEvent) {
    super.mouseEntered(with: event)
    controller?.onMouseEntered()
  }

  override func mouseExited(with event: NSEvent) {
    super.mouseExited(with: event)
    controller?.onMouseExited()
  }

  override func mouseDown(with event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)

    if controller?.isExpanded == true {
      // Check for button clicks inside expanded island
      if let candidate = currentCandidate {
        let saveRect = NSRect(x: bounds.width - 130, y: 14, width: 116, height: 30)
        let ignoreRect = NSRect(x: bounds.width - 220, y: 14, width: 80, height: 30)

        if NSPointInRect(location, saveRect) {
          controller?.saveCandidate(candidate)
          currentCandidate = nil
          needsDisplay = true
          return
        } else if NSPointInRect(location, ignoreRect) {
          currentCandidate = nil
          needsDisplay = true
          return
        }
      }

      // Open LaterBox button
      let openAppRect = NSRect(x: 14, y: 14, width: 120, height: 30)
      if NSPointInRect(location, openAppRect) {
        controller?.openLaterBox()
        return
      }

      // Toggle Watch Mode button
      let watchRect = NSRect(x: 142, y: 14, width: 110, height: 30)
      if NSPointInRect(location, watchRect) {
        controller?.toggleWatchMode()
        return
      }
    } else {
      // Clicking collapsed pill expands it immediately
      controller?.expand()
    }
  }

  // MARK: - Drag & Drop

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    isDragTarget = true
    if controller?.isExpanded == false {
      controller?.expand()
    }
    return .copy
  }

  override func draggingExited(_ sender: NSDraggingInfo?) {
    isDragTarget = false
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    isDragTarget = false
    let pasteboard = sender.draggingPasteboard
    var droppedItems: [String] = []

    if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
      for url in urls {
        droppedItems.append(url.isFileURL ? url.path : url.absoluteString)
      }
    } else if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
      for str in strings {
        droppedItems.append(str)
      }
    }

    guard !droppedItems.isEmpty else { return false }
    controller?.handleDroppedItems(droppedItems)
    return true
  }

  // MARK: - Drawing

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let isExpanded = controller?.isExpanded ?? false
    let cornerRadius: CGFloat = isExpanded ? 20.0 : 14.0

    // Draw Notch Pill / Island Body
    NSColor.black.withAlphaComponent(0.98).setFill()
    let path = NSBezierPath(
      roundedRect: bounds,
      xRadius: cornerRadius,
      yRadius: cornerRadius
    )
    path.fill()

    // Border highlight
    let borderColor = isDragTarget
      ? NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 0.9)
      : (isHovered
          ? NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 0.4)
          : NSColor.white.withAlphaComponent(0.12))
    borderColor.setStroke()
    path.lineWidth = isDragTarget ? 2.0 : 1.0
    path.stroke()

    if isExpanded {
      drawExpandedContent()
    } else {
      drawCollapsedContent()
    }
  }

  private func drawCollapsedContent() {
    // Glowing accent dot
    let dotRect = NSRect(x: 14, y: (bounds.height - 8) / 2, width: 8, height: 8)
    let dotColor = isWatching
      ? NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 1.0)
      : NSColor.white.withAlphaComponent(0.6)
    dotColor.setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    // Text label
    let text = currentCandidate != nil ? "1 Suggestion Ready" : "laterbox"
    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: NSColor.white,
      .font: NSFont.systemFont(ofSize: 11.5, weight: .semibold)
    ]
    let stringRect = NSRect(x: 28, y: (bounds.height - 14) / 2, width: bounds.width - 40, height: 16)
    text.draw(in: stringRect, withAttributes: attrs)
  }

  private func drawExpandedContent() {
    // Header Bar: "LATERBOX"
    let titleAttrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 1.0),
      .font: NSFont.systemFont(ofSize: 10, weight: .heavy),
      .kern: 0.8
    ]
    "LATERBOX DYNAMIC NOTCH".draw(at: NSPoint(x: 16, y: bounds.height - 24), withAttributes: titleAttrs)

    // Center Card: Candidate or Dropzone
    if let candidate = currentCandidate {
      let cardRect = NSRect(x: 14, y: 52, width: bounds.width - 28, height: 96)
      NSColor.white.withAlphaComponent(0.06).setFill()
      let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 10, yRadius: 10)
      cardPath.fill()

      let candidateTitleAttrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.white,
        .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
      ]
      let candidateTitleRect = NSRect(x: 24, y: cardRect.maxY - 28, width: cardRect.width - 20, height: 20)
      candidate.title.draw(in: candidateTitleRect, withAttributes: candidateTitleAttrs)

      if let url = candidate.url {
        let urlAttrs: [NSAttributedString.Key: Any] = [
          .foregroundColor: NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 0.8),
          .font: NSFont.systemFont(ofSize: 11, weight: .regular)
        ]
        let urlRect = NSRect(x: 24, y: cardRect.maxY - 46, width: cardRect.width - 20, height: 16)
        url.draw(in: urlRect, withAttributes: urlAttrs)
      }

      // Buttons
      drawButton(title: "Save to Box", rect: NSRect(x: bounds.width - 130, y: 14, width: 116, height: 30), isAccent: true)
      drawButton(title: "Ignore", rect: NSRect(x: bounds.width - 220, y: 14, width: 80, height: 30), isAccent: false)
    } else {
      // Drop zone prompt
      let dropRect = NSRect(x: 14, y: 52, width: bounds.width - 28, height: 96)
      NSColor.white.withAlphaComponent(0.04).setFill()
      let dropPath = NSBezierPath(roundedRect: dropRect, xRadius: 10, yRadius: 10)
      dropPath.fill()
      NSColor.white.withAlphaComponent(0.1).setStroke()
      dropPath.lineWidth = 1.0
      dropPath.stroke()

      let promptAttrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.white.withAlphaComponent(0.7),
        .font: NSFont.systemFont(ofSize: 12, weight: .medium)
      ]
      let promptText = isDragTarget ? "Release to save in LaterBox" : "Drop URLs, images, PDFs or text here to save"
      promptText.draw(at: NSPoint(x: 24, y: dropRect.midY + 4), withAttributes: promptAttrs)

      let subAttrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.white.withAlphaComponent(0.4),
        .font: NSFont.systemFont(ofSize: 10.5, weight: .regular)
      ]
      "Or let Watch Mode automatically capture articles and tabs".draw(at: NSPoint(x: 24, y: dropRect.midY - 16), withAttributes: subAttrs)

      // Footer Actions
      drawButton(title: "Open App", rect: NSRect(x: 14, y: 14, width: 120, height: 30), isAccent: false)
      let watchLabel = isWatching ? "Watch: ON" : "Watch: OFF"
      drawButton(title: watchLabel, rect: NSRect(x: 142, y: 14, width: 110, height: 30), isAccent: isWatching)
    }
  }

  private func drawButton(title: String, rect: NSRect, isAccent: Bool) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
    if isAccent {
      NSColor(red: 0.85, green: 0.95, blue: 0.3, alpha: 1.0).setFill()
      path.fill()
      let attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.black,
        .font: NSFont.systemFont(ofSize: 11.5, weight: .bold)
      ]
      let size = title.size(withAttributes: attrs)
      title.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attrs)
    } else {
      NSColor.white.withAlphaComponent(0.12).setFill()
      path.fill()
      let attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.white,
        .font: NSFont.systemFont(ofSize: 11.5, weight: .semibold)
      ]
      let size = title.size(withAttributes: attrs)
      title.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attrs)
    }
  }
}

/// Manages the floating NSPanel attached to the native macOS camera notch.
final class NotchPanelController {
  private(set) var panel: NSPanel?
  private(set) var notchView: NotchPanelView?
  private(set) var isExpanded: Bool = false

  private var collapseTimer: Timer?

  var onSaveCandidate: ((String, String?, String?) -> Void)?
  var onOpenLaterBox: (() -> Void)?
  var onToggleWatchMode: ((Bool) -> Void)?
  var onDroppedItems: (([String]) -> Void)?

  func show() {
    if let panel = panel {
      panel.orderFrontRegardless()
      return
    }

    guard let screen = targetScreen() else { return }

    let frame = calculateCollapsedFrame(for: screen)
    let panel = NSPanel(
      contentRect: frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isMovable = false
    panel.isReleasedWhenClosed = false

    let view = NotchPanelView(frame: NSRect(origin: .zero, size: frame.size))
    view.controller = self
    panel.contentView = view
    panel.orderFrontRegardless()

    self.panel = panel
    self.notchView = view
  }

  func hide() {
    panel?.orderOut(nil)
    panel = nil
    notchView = nil
  }

  func setWatchingState(_ isWatching: Bool) {
    notchView?.isWatching = isWatching
  }

  func presentCandidate(_ candidate: ScreenCandidate) {
    notchView?.currentCandidate = candidate
    // If a candidate is found, expand automatically so the user can quickly accept or ignore.
    expand()
  }

  func expand() {
    collapseTimer?.invalidate()
    collapseTimer = nil
    guard !isExpanded, let panel = panel, let screen = panel.screen ?? targetScreen() else { return }

    isExpanded = true
    let expandedFrame = calculateExpandedFrame(for: screen)

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.22
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      panel.animator().setFrame(expandedFrame, display: true)
    } completionHandler: { [weak self] in
      self?.notchView?.needsDisplay = true
    }
  }

  func collapse() {
    collapseTimer?.invalidate()
    collapseTimer = nil
    guard isExpanded, let panel = panel, let screen = panel.screen ?? targetScreen() else { return }

    isExpanded = false
    let collapsedFrame = calculateCollapsedFrame(for: screen)

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.22
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      panel.animator().setFrame(collapsedFrame, display: true)
    } completionHandler: { [weak self] in
      self?.notchView?.needsDisplay = true
    }
  }

  func onMouseEntered() {
    collapseTimer?.invalidate()
    collapseTimer = nil
    expand()
  }

  func onMouseExited() {
    collapseTimer?.invalidate()
    // 500ms delay so quick cursor moves don't flicker
    collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
      self?.collapse()
    }
  }

  func saveCandidate(_ candidate: ScreenCandidate) {
    onSaveCandidate?(candidate.title, candidate.url, candidate.snippet)
    collapse()
  }

  func openLaterBox() {
    onOpenLaterBox?()
  }

  func toggleWatchMode() {
    let nextState = !(notchView?.isWatching ?? false)
    notchView?.isWatching = nextState
    onToggleWatchMode?(nextState)
  }

  func handleDroppedItems(_ items: [String]) {
    onDroppedItems?(items)
  }

  // MARK: - Geometry & Notch Sizing

  private func calculateCollapsedFrame(for screen: NSScreen) -> NSRect {
    let notchWidth = calculateNotchWidth(screen)
    let hasNotch: Bool
    let notchHeight: CGFloat
    if #available(macOS 12.0, *) {
      notchHeight = screen.safeAreaInsets.top
      hasNotch = notchHeight > 0
    } else {
      notchHeight = 0
      hasNotch = false
    }

    let width: CGFloat = hasNotch ? max(notchWidth + 24, 220) : 220
    let height: CGFloat = hasNotch ? max(notchHeight, 36) : 34

    let x = screen.frame.midX - width / 2
    let y = screen.frame.maxY - height
    return NSRect(x: x, y: y, width: width, height: height)
  }

  private func calculateExpandedFrame(for screen: NSScreen) -> NSRect {
    let width: CGFloat = 460
    let height: CGFloat = 176

    let x = screen.frame.midX - width / 2
    let y = screen.frame.maxY - height
    return NSRect(x: x, y: y, width: width, height: height)
  }

  private func calculateNotchWidth(_ screen: NSScreen) -> CGFloat {
    if #available(macOS 12.0, *) {
      if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
        return max(0, right.minX - left.maxX)
      }
    }
    return 180
  }

  private func targetScreen() -> NSScreen? {
    let mouse = NSEvent.mouseLocation
    return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
  }
}
