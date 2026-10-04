import SwiftUI
import SwiftData

public struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draft = CaptureDraft()
    @State private var savedItem: LBItem?
    @State private var error: String?
    @State private var editing = false
    public init() {}
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let item = savedItem {
                        Text("Saved ‘\(item.title)’").font(.headline)
                        HStack {
                            Button("Edit") { editing = true }
                            Button("Undo") {
                                item.status = "deleted"; item.updatedAt = Date(); item.isSyncPending = true
                                do { try context.save(); savedItem = nil; draft = CaptureDraft(); Task { await SyncCoordinator.shared.syncPendingItems(context: context) } }
                                catch { item.status = "inbox"; self.error = error.localizedDescription }
                            }
                            Button("Done") { dismiss() }
                        }
                    } else {
                        GuidedCaptureView(draft: $draft) {
                            do { savedItem = try SyncCoordinator.shared.saveDraft(draft, context: context); error = nil }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                    if let error { Text(error).foregroundStyle(.red) }
                }.padding(20)
            }
            .navigationTitle("Save an item")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $editing) { if let item = savedItem { NavigationStack { ItemDetailView(item: item) } } }
        }
    }
}
