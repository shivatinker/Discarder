import SwiftUI

public struct CardStackLayout: Layout {
    let spacing: CGFloat
    let overlap: CGFloat
    
    public init(spacing: CGFloat = 0, overlap: CGFloat = 0) {
        self.spacing = spacing
        self.overlap = overlap
    }
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxHeight = sizes.map(\.height).max() ?? 0
        
        // Always use the proposed width if available
        if let proposedWidth = proposal.width {
            return CGSize(
                width: proposedWidth,
                height: maxHeight
            )
        }
        
        // Calculate minimum width needed
        let totalWidth = sizes.reduce(0) { sum, size in
            sum + size.width
        }
        let overlapWidth = CGFloat(subviews.count - 1) * self.overlap
        let spacingWidth = CGFloat(subviews.count - 1) * self.spacing
        
        return CGSize(
            width: totalWidth - overlapWidth + spacingWidth,
            height: maxHeight
        )
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalWidth = sizes.reduce(0) { $0 + $1.width }
        let spacingWidth = CGFloat(subviews.count - 1) * self.spacing
        
        // Calculate how to distribute cards across the full width
        let availableWidth = bounds.width
        let contentWidth = totalWidth + spacingWidth
        
        // Calculate adaptive overlap to fill the available width
        let adaptiveOverlap: CGFloat
        if subviews.count > 1 {
            // Calculate how much we need to overlap to fill the width
            let totalOverlapNeeded = contentWidth - availableWidth
            adaptiveOverlap = max(0, totalOverlapNeeded / CGFloat(subviews.count - 1))
        }
        else {
            adaptiveOverlap = 0
        }
        
        var x = bounds.minX
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            let position = CGPoint(
                x: x,
                y: bounds.minY + (bounds.height - size.height) / 2
            )
            
            subview.place(at: position, proposal: ProposedViewSize(size))
            
            // Move x position for next card, considering adaptive overlap
            x += size.width - adaptiveOverlap + self.spacing
        }
    }
}

public struct CardStack<Content: View>: View {
    private let content: Content
    private let spacing: CGFloat
    private let overlap: CGFloat
    
    public init(
        spacing: CGFloat = 0,
        overlap: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.spacing = spacing
        self.overlap = overlap
    }
    
    public var body: some View {
        CardStackLayout(spacing: self.spacing, overlap: self.overlap) {
            self.content
        }
        .frame(maxWidth: .infinity)
    }
}

// Example usage:
struct CardStackExample: View {
    var body: some View {
        VStack {
            CardStack(spacing: 10, overlap: 20) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 100, height: 150)
                        .overlay(
                            Text("\(index + 1)")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .padding()
            
            // Example with different width
            CardStack(spacing: 10, overlap: 20) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 100, height: 150)
                        .overlay(
                            Text("\(index + 1)")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                }
            }
            .frame(width: 300)
            .frame(height: 150)
            .padding()
        }
    }
}

#Preview {
    CardStackExample()
}
