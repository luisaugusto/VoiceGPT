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

    @Test func chatResponseParserExtractsAssistantTextAndMemoryUpdate() async throws {
        let rawResponse = """
        {"assistant_response":"Absolutely — I can help with that.","memory_update":"The user is gluten free."}
        """

        let parsed = OpenAIService.parseChatResponse(rawResponse)

        #expect(parsed.assistantText == "Absolutely — I can help with that.")
        #expect(parsed.memoryUpdate == "The user is gluten free.")
    }

    @Test func chatResponseParserFallsBackToPlainTextWithoutMemoryUpdate() async throws {
        let parsed = OpenAIService.parseChatResponse("Sure, let's do it.")

        #expect(parsed.assistantText == "Sure, let's do it.")
        #expect(parsed.memoryUpdate == nil)
    }

    @Test func savingPersonalContextUpdateAppendsNewDurableContext() async throws {
        let vm = AppViewModel()
        let settings = AppSettings()
        settings.personalContext = "The user prefers brief answers."

        var didSave = false
        vm.savePersonalContextUpdate(
            "The user is gluten free.",
            settings: settings,
            save: { didSave = true },
            rollback: {}
        )

        #expect(didSave)
        #expect(settings.personalContext == "The user prefers brief answers.\nThe user is gluten free.")
    }

    @Test func failedPersonalContextUpdateSaveRestoresPreviousContext() async throws {
        let vm = AppViewModel()
        let settings = AppSettings()
        settings.personalContext = "The user prefers brief answers."

        var didRollback = false
        vm.savePersonalContextUpdate(
            "The user is gluten free.",
            settings: settings,
            save: { throw TestError.saveFailed },
            rollback: { didRollback = true }
        )

        #expect(didRollback)
        #expect(settings.personalContext == "The user prefers brief answers.")
        #expect(vm.errorMessage == "Unable to save personal context: Save failed")
    }

    @Test func duplicatePersonalContextUpdateIsIgnored() async throws {
        let vm = AppViewModel()
        let settings = AppSettings()
        settings.personalContext = "The user is gluten free."

        var didSave = false
        vm.savePersonalContextUpdate(
            "The user is gluten free.",
            settings: settings,
            save: { didSave = true },
            rollback: {}
        )

        #expect(!didSave)
        #expect(settings.personalContext == "The user is gluten free.")
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
