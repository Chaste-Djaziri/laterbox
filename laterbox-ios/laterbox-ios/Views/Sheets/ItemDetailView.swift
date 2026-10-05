//
//  ItemDetailView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import QuickLook

public struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable public var item: LBItem
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var editedNote: String = ""
    @State private var showingDeleteConfirm = false
    @State private var saveError: String?
    @State private var attachmentURL: URL?
    @State private var tagsText = ""

    public init(item: LBItem) {
        self.item = item
        self._editedNote = State(initialValue: item.noteContent ?? "")
        self._tagsText = State(initialValue: item.tags.joined(separator: ", "))
    }

    public var body: some View {
        ZStack {
            LiquidGlassBackground().quickLookPreview($attachmentURL)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let data = item.attachmentsData, let files = try? JSONDecoder().decode([SharedAttachment].self, from: data) {
                        ForEach(files) { file in
                            Button { attachmentURL = try? SharedCaptureStore.fileURL(file) } label: {
                                Label(file.name, systemImage: "paperclip")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Rich Visual Banner
                    RichMediaBanner(
                        type: item.parsedContentType,
                        url: item.url,
                        title: item.title,
                        previewImageUrl: item.previewImageUrl
                    )

                    // Title & Source Metadata Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            if let domain = item.domain, !domain.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "globe")
                                        .font(.caption2)
                                    Text(domain)
                                        .font(.caption2.weight(.bold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.background))
                                .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                .foregroundColor(AppTheme.textSecondary)
                            }

                            Text(item.parsedContentType.rawValue.capitalized)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.accent))
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Text(item.parsedStatus.title)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.background))
                                .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        TextField("Title", text: $item.title, axis: .vertical)
                            .onChange(of: item.title) { _, _ in persistEdit() }
                            .font(.title3.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1...4)

                        if let desc = item.metadataDescription, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc) {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(3)
                        } else if !item.summary.isEmpty {
                            Text(item.summary)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(3)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                            Text("Saved \(item.createdAt, format: .dateTime.month().day().year())")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 18)

                    // Actions Bar: Safari, Share, Status
                    HStack(spacing: 10) {
                        if let urlStr = item.url, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "safari")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Open")
                                        .font(.subheadline.weight(.bold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .liquidGlassCard(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)

                            ShareLink(item: url) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Share")
                                        .font(.subheadline.weight(.bold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .liquidGlassCard(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            if item.status == ItemStatus.saved.rawValue {
                                coordinator.scheduleItem(item: item, date: Date(), context: modelContext)
                            } else {
                                coordinator.markDone(item: item, context: modelContext)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: item.status == ItemStatus.saved.rawValue ? "arrow.uturn.backward" : "checkmark")
                                    .font(.subheadline.weight(.bold))
                                Text(item.status == ItemStatus.saved.rawValue ? "Return" : "Done")
                                    .font(.subheadline.weight(.bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                item.status == ItemStatus.saved.rawValue
                                    ? AnyShapeStyle(AppTheme.accent)
                                    : AnyShapeStyle(AppTheme.darkSurface)
                            )
                            .foregroundColor(item.status == ItemStatus.saved.rawValue ? AppTheme.textPrimary : AppTheme.textOnDark)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        }
                    }

                    // Return Schedule Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RETURN SCHEDULE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        if let ret = item.returnAt {
                            let isTodayOrOverdue = Calendar.current.isDateInToday(ret) || ret < Date()
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(isTodayOrOverdue ? AppTheme.darkSurface : AppTheme.accent)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: isTodayOrOverdue ? "exclamationmark.clock.fill" : "calendar.badge.clock")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(isTodayOrOverdue ? AppTheme.accent : AppTheme.darkSurface)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isTodayOrOverdue ? "Due Today" : "Scheduled Return")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(ret, format: .dateTime.month().day().year())
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Button("Clear") {
                                    item.returnAt = nil
                                    persistEdit()
                                    LBHaptic.light()
                                }
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.red.opacity(0.08)))
                            }
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 16)
                        } else {
                            HStack(spacing: 8) {
                                Button(action: {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, context: modelContext)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.caption2.weight(.bold))
                                        Text("Tomorrow")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(AppTheme.accent))
                                    .foregroundColor(AppTheme.textPrimary)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, context: modelContext)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.caption2.weight(.bold))
                                        Text("Weekend")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(AppTheme.cardBackground))
                                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                    .foregroundColor(AppTheme.textPrimary)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    coordinator.scheduleItem(item: item, date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, context: modelContext)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.caption2.weight(.bold))
                                        Text("Next Week")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(AppTheme.cardBackground))
                                    .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                    .foregroundColor(AppTheme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Organization & Tags Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ORGANIZATION & TAGS")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        VStack(alignment: .leading, spacing: 12) {
                            // Category Row
                            HStack(spacing: 10) {
                                Image(systemName: "folder")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(width: 20)
                                TextField("Add category...", text: $item.category)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .onChange(of: item.category) { _, _ in persistEdit() }
                            }

                            Divider()

                            // Tags Row
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "tag")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(width: 20)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Tags, separated by commas...", text: $tagsText)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .onChange(of: tagsText) { _, text in
                                            item.tags = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }
                                            persistEdit()
                                        }

                                    if !item.tags.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(item.tags, id: \.self) { tag in
                                                    Text("#\(tag)")
                                                        .font(.caption2.weight(.semibold))
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background(Capsule().fill(AppTheme.background))
                                                        .overlay(Capsule().strokeBorder(AppTheme.cardBorder, lineWidth: 1))
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Description if present
                            if let desc = item.metadataDescription, !desc.isEmpty, !LinkMetadataLoader.isGenericDescription(desc), desc != item.summary {
                                Divider()
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "text.alignleft")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Description")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineSpacing(3)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                        )
                                )
                            }

                            // AI Summary if present
                            if !item.summary.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("AI Summary")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Text(item.summary)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineSpacing(3)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                        )
                                )
                            }

                            // Original content preview if present
                            if let original = item.textContent, !original.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Captured Content")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(original)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .textSelection(.enabled)
                                        .lineLimit(8)
                                }
                            }

                            // Formatted content if present
                            if !item.formattedContent.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Formatted Content")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(item.formattedContent)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .textSelection(.enabled)
                                        .lineLimit(8)
                                }
                            }

                            if let saveError {
                                Text(saveError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .liquidGlassCard(cornerRadius: 18)
                    }

                    // Notes Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PERSONAL NOTES")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        ZStack(alignment: .topLeading) {
                            if editedNote.isEmpty {
                                Text("Add personal thoughts, takeaways, or reminders...")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textTertiary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $editedNote)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .frame(minHeight: 110)
                                .onChange(of: editedNote) { _, newVal in
                                    item.noteContent = newVal
                                    persistEdit()
                                }
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // Delete Button
                    Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete Item")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .onDisappear { Task { await coordinator.syncPendingItems(context: modelContext) } }
        .task {
            let needsTitleHeal = LinkMetadataLoader.isGenericTitle(item.title)
            let needsDescHeal = item.metadataDescription != nil && LinkMetadataLoader.isGenericDescription(item.metadataDescription)
            let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist"]
            let hasJunkTags = item.tags.contains { junkTags.contains($0.lowercased()) }
            if (needsTitleHeal || needsDescHeal || hasJunkTags) && item.url != nil {
                await coordinator.enrich(item: item, context: modelContext)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    coordinator.toggleFavorite(item: item, context: modelContext)
                }) {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .foregroundColor(item.favorite ? AppTheme.amber : AppTheme.textPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                coordinator.deleteItem(item: item, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    private func persistEdit() {
        item.updatedAt = Date()
        item.isSyncPending = true
        do { try modelContext.save(); saveError = nil }
        catch { saveError = error.localizedDescription }
    }

}
