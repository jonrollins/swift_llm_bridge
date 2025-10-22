import Foundation

/// Server-Sent Events (SSE) parser for LLM streaming responses
/// Handles SSE format parsing across different LLM providers
struct SSEParser {

    /// Parses an SSE data line and returns the JSON content if valid
    /// - Parameters:
    ///   - line: The raw SSE line to parse
    ///   - target: The LLM provider target
    /// - Returns: The parsed JSON string, or nil if the line should be ignored
    static func parseDataLine(_ line: String, target: LLMTarget) -> String? {
        // Early return for empty lines
        guard !line.isEmpty else { return nil }

        var jsonLine = line

        // Handle SSE format for providers that use it
        if target == .lmstudio || target == .claude || target == .openai {
            // Handle "data: " prefix
            if line.hasPrefix("data: ") {
                jsonLine = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)

                // Ignore [DONE] markers and empty data
                if jsonLine == "[DONE]" || jsonLine.isEmpty {
                    return nil
                }
            }
            // Ignore event lines, comments, and empty lines
            else if line.hasPrefix("event:") || line.hasPrefix(":") {
                return nil
            }
            // Ignore non-JSON lines
            else if !line.hasPrefix("{") {
                return nil
            }
        }

        // Return nil for empty JSON lines
        return jsonLine.isEmpty ? nil : jsonLine
    }

    /// Parses a JSON line into a dictionary
    /// - Parameter jsonLine: The JSON string to parse
    /// - Returns: The parsed dictionary, or nil if parsing fails
    static func parseJSON(_ jsonLine: String) -> [String: Any]? {
        guard let data = jsonLine.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    /// Parses an SSE line and returns the JSON dictionary
    /// - Parameters:
    ///   - line: The raw SSE line
    ///   - target: The LLM provider target
    /// - Returns: The parsed JSON dictionary, or nil if parsing fails
    static func parseLineToJSON(_ line: String, target: LLMTarget) -> [String: Any]? {
        guard let jsonLine = parseDataLine(line, target: target) else {
            return nil
        }
        return parseJSON(jsonLine)
    }
}
