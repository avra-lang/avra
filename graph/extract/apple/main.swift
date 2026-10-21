// Closed choices on Apple's on-device model: one JSON request per stdin line,
// {"context","question","options"}; one JSON answer per line, {"choice","p"}.
// Guided generation constrains the answer to an option; the framework exposes
// no probabilities, so p is one-hot. `--check` reports availability only.
import Foundation
import FoundationModels

struct Request: Decodable { let context: String; let question: String; let options: [String] }

func emit(_ object: [String: Any]) {
    let data = try! JSONSerialization.data(withJSONObject: object)
    FileHandle.standardOutput.write(data + Data("\n".utf8))
}

let model = SystemLanguageModel.default
switch model.availability {
case .available:
    if CommandLine.arguments.contains("--check") { emit(["available": true]); exit(0) }
case .unavailable(let reason):
    emit(["available": false, "reason": String(describing: reason)])
    exit(CommandLine.arguments.contains("--check") ? 0 : 1)
}

while let line = readLine() {
    guard let req = try? JSONDecoder().decode(Request.self, from: Data(line.utf8)) else {
        emit(["error": "bad request"]); continue
    }
    let started = Date()
    do {
        let session = LanguageModelSession()
        let schema = try GenerationSchema(root: DynamicGenerationSchema(name: "Choice", anyOf: req.options), dependencies: [])
        let prompt = "\(req.context)\n\n\(req.question)\nChoose exactly one of the given options."
        let reply = try await session.respond(to: prompt, schema: schema, options: GenerationOptions(sampling: .greedy))
        let choice = try reply.content.value(String.self)
        emit(["choice": choice, "p": req.options.map { $0 == choice ? 1.0 : 0.0 }, "s": Date().timeIntervalSince(started)])
    } catch {
        emit(["error": String(describing: error), "s": Date().timeIntervalSince(started)])
    }
}
