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

    @Test func cleanedConversationTitleRemovesAIFormatting() async throws {
        let title = OpenAIService.cleanedTitle("  \"Planning a Kyoto Trip.\"  ")

        #expect(title == "Planning a Kyoto Trip")
    }

    @Test func emptyCleanedConversationTitleFallsBackToDefault() async throws {
        let title = OpenAIService.cleanedTitle("  ...  ")

        #expect(title == "New conversation")
    }

    @Test func cleanedConversationTitleLimitsLength() async throws {
        let title = OpenAIService.cleanedTitle(String(repeating: "a", count: 80))

        #expect(title.count == 60)
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
