import SwiftUI
import SwiftData

struct HistoryPane: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.modelContext) private var context
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    @State private var conversationToDelete: Conversation?

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(.regularMaterial)
                        .ignoresSafeArea()
                        .overlay(alignment: .trailing) {
                            Rectangle()
                                .fill(Color.glassBorder)
                                .frame(width: 1)
                        }

                    VStack(alignment: .leading, spacing: 0) {
                        header
                        newConversationButton
                        conversationList
                    }
                }
                .frame(width: min(geo.size.width * 0.84, 340))

                Spacer()
            }
        }
        .alert("Delete conversation?", isPresented: deleteConfirmationPresented, presenting: conversationToDelete) { conversation in
            Button("Delete", role: .destructive) {
                vm.deleteConversation(conversation, context: context)
                conversationToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
        } message: { _ in
            Text("This permanently deletes the conversation and all of its messages. This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("VoiceGPT")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.inkPrimary)
            Spacer()
            Button {
                withAnimation(DS.easeGlass) { vm.isHistoryOpen = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    vm.isSettingsOpen = true
                }
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.inkSecondary)
                    .glassCircle(size: 40)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // MARK: - New conversation

    private var newConversationButton: some View {
        Button {
            vm.newConversation(context: context)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text("New conversation")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.75)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .shadow(color: accentColor.opacity(0.35), radius: 8, y: 3)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Conversation list

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if !todayConversations.isEmpty {
                    sectionHeader("Today")
                    ForEach(todayConversations) { row(for: $0) }
                }
                if !earlierConversations.isEmpty {
                    sectionHeader("Earlier")
                    ForEach(earlierConversations) { row(for: $0) }
                }
            }
            .padding(.horizontal, 10)
        }
    }

    @ViewBuilder
    private func row(for conv: Conversation) -> some View {
        let isActive = vm.activeConversation?.id == conv.id
        Button {
            vm.activeConversation = conv
            withAnimation(DS.easeGlass) { vm.isHistoryOpen = false }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(conv.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.inkPrimary)
                    .lineLimit(1)
                if !conv.preview.isEmpty {
                    Text(conv.preview)
                        .font(.system(size: 13))
                        .foregroundColor(.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.glassFill : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isActive ? Color.glassBorder : .clear, lineWidth: 1)
                    )
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                conversationToDelete = conv
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var deleteConfirmationPresented: Binding<Bool> {
        Binding(
            get: { conversationToDelete != nil },
            set: { isPresented in
                if !isPresented {
                    conversationToDelete = nil
                }
            }
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    // MARK: - Grouping

    private var todayConversations: [Conversation] {
        conversations.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var earlierConversations: [Conversation] {
        conversations.filter { !Calendar.current.isDateInToday($0.createdAt) }
    }

    private var accentColor: Color {
        Color.accent("indigo")
    }
}
