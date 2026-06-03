//
//  VoiceGPTTests.swift
//  VoiceGPTTests
//
//  Created by Luis Augusto on 6/3/26.
//

import Foundation
import Testing
@testable import VoiceGPT

struct VoiceGPTTests {

    @Test func conversationSearchMatchesTitleCaseInsensitively() async throws {
        let conversation = Conversation(title: "Trip Planning")

        #expect(conversation.matchesSearch("trip"))
        #expect(conversation.matchesSearch("  PLANNING  "))
    }

    @Test func conversationSearchMatchesAnyMessageCaseInsensitively() async throws {
        let conversation = Conversation(title: "Untitled")
        let firstMessage = Message(role: "user", text: "Can you summarize this article?", conversation: conversation)
        let secondMessage = Message(role: "assistant", text: "Here are the key takeaways.", conversation: conversation)
        conversation.messages.append(firstMessage)
        conversation.messages.append(secondMessage)

        #expect(conversation.matchesSearch("KEY takeaways"))
        #expect(conversation.matchesSearch("summarize"))
    }

    @Test func conversationSearchReturnsFalseWhenTitleAndMessagesDoNotMatch() async throws {
        let conversation = Conversation(title: "Dinner Ideas")
        conversation.messages.append(Message(role: "user", text: "Find a quick pasta recipe.", conversation: conversation))

        #expect(!conversation.matchesSearch("workout"))
    }

    @Test func failedActiveConversationDeletionRollsBackAndRestoresSelection() async throws {
        let vm = AppViewModel()
        let conversation = Conversation()
        vm.activeConversation = conversation

        var didDelete = false
        var didRollback = false

        vm.deleteConversation(
            conversation,
            delete: { didDelete = true },
            save: { throw TestError.saveFailed },
            rollback: { didRollback = true }
        )

        #expect(didDelete)
        #expect(didRollback)
        #expect(vm.activeConversation === conversation)
        #expect(vm.errorMessage == "Unable to delete conversation: Save failed")
    }

    @Test func failedInactiveConversationDeletionRollsBackWithoutChangingSelection() async throws {
        let vm = AppViewModel()
        let activeConversation = Conversation()
        let deletedConversation = Conversation()
        vm.activeConversation = activeConversation

        var didRollback = false

        vm.deleteConversation(
            deletedConversation,
            delete: {},
            save: { throw TestError.saveFailed },
            rollback: { didRollback = true }
        )

        #expect(didRollback)
        #expect(vm.activeConversation === activeConversation)
        #expect(vm.errorMessage == "Unable to delete conversation: Save failed")
    }

    @Test func successfulActiveConversationDeletionLeavesSelectionCleared() async throws {
        let vm = AppViewModel()
        let conversation = Conversation()
        vm.activeConversation = conversation

        var didRollback = false

        vm.deleteConversation(
            conversation,
            delete: {},
            save: {},
            rollback: { didRollback = true }
        )

        #expect(!didRollback)
        #expect(vm.activeConversation == nil)
        #expect(vm.errorMessage == nil)
    }
}

private enum TestError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            "Save failed"
        }
    }
}
