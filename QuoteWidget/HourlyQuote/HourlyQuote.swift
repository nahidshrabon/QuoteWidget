//
//  HourlyQuote.swift
//  HourlyQuote
//
//  Created by Md. Nahidul Islam on 26/10/2024.
//

import AppIntents
import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(
        in context: Context
    ) -> QuoteEntry { .init() }
    
    func snapshot(
        for configuration: CategoryIntent,
        in context: Context
    ) async -> QuoteEntry { .init() }
    
    func timeline(
        for configuration: CategoryIntent,
        in context: Context
    ) async -> Timeline<QuoteEntry> {
        QuoteEntry.category = configuration.category?.id
        
        return Timeline(
            entries: [QuoteEntry()],
            policy: .after(Date().addingTimeInterval(3600))
        )
    }
}

struct QuoteEntry: TimelineEntry {
    static let defaultBackground = UIImage(resource: .background)
    
    static var currentQuote = Quote(
        quote: "Widget Rocks!",
        author: "iOS Ninja"
    )
    
    static var category = Category.categories.first?.id
    
    let date: Date
    let quote: Quote
    let background: UIImage
    
    init(
        date: Date = .now,
        quote: Quote = Self.currentQuote,
        background: UIImage = Self.defaultBackground
    ) {
        self.date = date
        self.quote = quote
        self.background = background
    }
}

struct Quote: Codable {
    let quote: String
    let author: String
}

struct NextIntent: AppIntent {
    static var title: LocalizedStringResource = "Next"
    
    func perform() async throws -> some IntentResult {
        guard
            let url = URL(string: "https://api.api-ninjas.com/v1/quotes?category=\(QuoteEntry.category ?? "art")")
        else {
            return .result()
        }
        
        var request = URLRequest(url: url)
        request.setValue(
            "LTcQcWdpNOR/i94yIWJZ+w==xPCYvXMAKUAiukMK",
            forHTTPHeaderField: "X-Api-Key"
        )
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedData = try JSONDecoder().decode([Quote].self, from: data)
        
        guard let quote = decodedData.first else {
            return .result()
        }
        
        print(quote)
        QuoteEntry.currentQuote = quote
        return .result()
    }
}

struct CategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Category"
    static var description: LocalizedStringResource = "Configure a category"
    
    @Parameter(title: "Category")
    var category: Category?

    init(category: Category) {
        self.category = category
    }

    init() {}
}

struct Category: AppEntity {
    let id: String
    let avatar: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Categories"
    static var defaultQuery = CategoryQuery()
            
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(avatar) \(id)")
    }

    static let categories: [Category] = [
        Category(id: "art", avatar: "🎨"),
        Category(id: "beauty", avatar: "👩"),
        Category(id: "education", avatar: "🧑‍🎓"),
        Category(id: "family", avatar: "👫")
    ]
}

struct CategoryQuery: EntityQuery {
    func entities(for identifiers: [Category.ID]) async throws -> [Category] {
        Category.categories.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [Category] {
        Category.categories
    }
    
    func defaultResult() async -> Category? {
        try? await suggestedEntities().first
    }
}


struct HourlyQuoteEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            
            Text(entry.quote.quote)
                .lineLimit(4)
                .fontWeight(.light)
                .fontDesign(.serif)
                .font(.headline)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)
            
            HStack {
                Image(systemName: "quote.bubble")
                
                Text(entry.quote.author)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .font(.subheadline)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.symbolEffect)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                Button(intent: NextIntent()) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.borderless)
                .tint(.black)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Image(uiImage: entry.background)
                .resizable()
        }
    }
}

struct HourlyQuote: Widget {
    let kind: String = "HourlyQuote"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CategoryIntent.self,
            provider: Provider()
        ) { entry in
            HourlyQuoteEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemMedium) {
    HourlyQuote()
} timeline: {
    QuoteEntry()
    QuoteEntry(quote: .init(
        quote: "Hello World",
        author: "John"
    ))
}
