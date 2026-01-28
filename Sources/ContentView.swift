import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var urlString: String = "https://www.ppp-online.nl/lidmaatschap/vind-een-lid/"
    @State private var logic = ScraperLogic()
    @State private var searchText: String = ""
    
    var filteredEmails: [String] {
        let emailList = Array(logic.emails).sorted()
        if searchText.isEmpty {
            return emailList
        }
        return emailList.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with URL input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Email Scraper")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top)
                    
                    HStack {
                        TextField("Enter URL to scrape...", text: $urlString)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                            .onSubmit {
                                startScraping()
                            }
                        
                        Button(action: startScraping) {
                            if logic.isScanning {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Scrape")
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(logic.isScanning || urlString.isEmpty)
                    }
                }
                .padding()
                .background(.background)
                
                Divider()
                
                // Result Count bar
                if !logic.emails.isEmpty {
                    HStack {
                        Text("\(logic.emails.count) email(s) found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button("Clear") {
                            logic.emails.removeAll()
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                    
                    Divider()
                }
                
                // Results Area
                if let error = logic.errorMessage {
                    ContentUnavailableView(
                        "Scraping Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if logic.emails.isEmpty && !logic.isScanning {
                    ContentUnavailableView(
                        "No Emails Found",
                        systemImage: "mail.stack",
                        description: Text("Enter a URL and click Scrape to find email addresses.")
                    )
                } else {
                    List {
                        ForEach(filteredEmails, id: \.self) { email in
                            EmailRow(email: email) {
                                copyToClipboard(email)
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: exportResults) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .help("Export results to file")
                    .disabled(logic.emails.isEmpty)
                    .keyboardShortcut("e", modifiers: .command)
                    
                    Button(action: copyAll) {
                        Label("Copy All", systemImage: "doc.on.doc.fill")
                    }
                    .help("Copy all emails to clipboard")
                    .disabled(logic.emails.isEmpty)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .searchable(text: $searchText, prompt: "Search emails...")
        }
        .frame(minWidth: 600, minHeight: 450)
    }
    
    private func startScraping() {
        Task {
            await logic.scan(urlPath: urlString)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func copyAll() {
        let allEmails = Array(logic.emails).sorted().joined(separator: "\n")
        copyToClipboard(allEmails)
    }
    
    private func exportResults() {
        let allEmails = Array(logic.emails).sorted().joined(separator: "\n")
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "scraped_emails.txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try allEmails.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    logic.errorMessage = "Failed to save file: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct EmailRow: View {
    let email: String
    let onCopy: () -> Void
    @State private var justCopied = false
    
    var body: some View {
        HStack {
            Image(systemName: "envelope.fill")
                .foregroundStyle(.blue.gradient)
                .font(.system(size: 14))
            
            Text(email)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
            
            Spacer()
            
            Button {
                onCopy()
                withAnimation {
                    justCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        justCopied = false
                    }
                }
            } label: {
                Image(systemName: justCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundStyle(justCopied ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help(justCopied ? "Copied!" : "Copy to clipboard")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
