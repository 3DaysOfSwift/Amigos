import Foundation
@testable import Amigos

actor ScriptedAmigoGenerator: AmigoReplyGenerating {
    private var outcomes: [Result<GeneratedAmigoReply, OnDeviceChatError>]
    private(set) var calls = 0
    private(set) var prompts: [String] = []
    private(set) var instructions: [String] = []
    private(set) var purposes: [AmigoGenerationPurpose] = []

    init(_ outcomes: [Result<GeneratedAmigoReply, OnDeviceChatError>]) { self.outcomes = outcomes }

    func generate(instructions: String, prompt: String, purpose: AmigoGenerationPurpose) throws -> GeneratedAmigoReply {
        purposes.append(purpose)
        return try generate(instructions: instructions, prompt: prompt)
    }

    func generate(instructions: String, prompt: String) throws -> GeneratedAmigoReply {
        calls += 1
        prompts.append(prompt)
        self.instructions.append(instructions)
        guard !outcomes.isEmpty else { throw TestFailure.unavailable }
        return try outcomes.removeFirst().get()
    }
}
