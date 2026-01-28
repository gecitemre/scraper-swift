import Foundation

@Observable
class ScraperLogic {
    var emails: Set<String> = []
    var isScanning = false
    var errorMessage: String?
    
    // Regex for finding emails
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    func scan(urlPath: String) async {
        guard let url = URL(string: urlPath) else {
            errorMessage = "Invalid URL"
            return
        }
        
        await MainActor.run {
            isScanning = true
            errorMessage = nil
            emails.removeAll()
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "ScraperError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode HTML content"])
            }
            
            let foundEmails = extractEmails(from: html)
            
            await MainActor.run {
                self.emails = foundEmails
                self.isScanning = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isScanning = false
            }
        }
    }
    
    private func extractEmails(from text: String) -> Set<String> {
        var results = Set<String>()
        
        // Pattern for standard email
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                var email = nsString.substring(with: match.range).lowercased()
                // Basic cleanup: remove any trailing dots or punctuation that might be caught
                if email.hasSuffix(".") { email.removeLast() }
                results.insert(email)
            }
            
            // Specifically look for mailto links to be more thorough
            let mailtoPattern = "mailto:([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64})"
            let mailtoRegex = try NSRegularExpression(pattern: mailtoPattern, options: .caseInsensitive)
            let mailtoMatches = mailtoRegex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in mailtoMatches {
                if match.numberOfRanges > 1 {
                    let email = nsString.substring(with: match.range(at: 1)).lowercased()
                    results.insert(email)
                }
            }
            
        } catch {
            print("Regex error: \(error)")
        }
        
        return results
    }
}
