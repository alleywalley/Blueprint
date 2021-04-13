import XCTest
@testable import BlueprintUI

class ElementContentTests: XCTestCase {

    func test_measurement_caching() {
        
        let environment = Environment.empty
        
        let element = MeasurableElement()
        
        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)
        
        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)
        
        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)
    }
    
    func test_noChildren() {
        let container = ElementContent(layout: FrameLayout())
        XCTAssertEqual(container.childCount, 0)
        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize(width: 100, height: 100)), environment: .empty),
            CGSize.zero)
    }

    func test_singleChild() {
        let frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        let container = ElementContent(layout: FrameLayout()) {
            $0.add(traits: frame, element: SimpleElement())
        }

        let children = container
            .testLayout(attributes: LayoutAttributes(frame: .zero))
            .map { $0.node }

        XCTAssertEqual(children.count, 1)

        XCTAssertEqual(children[0].layoutAttributes, LayoutAttributes(frame: frame))

        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize.zero), environment: .empty),
            CGSize(width: frame.maxX, height: frame.maxY))
    }

    func test_multipleChildren() {

        let frame1 = CGRect(x: 0, y: 0, width: 20, height: 20)
        let frame2 = CGRect(x: 200, y: 300, width: 400, height: 500)

        let container = ElementContent(layout: FrameLayout()) {
            $0.add(traits: frame1, element: SimpleElement())
            $0.add(traits: frame2, element: SimpleElement())
        }

        let children = container
            .testLayout(attributes: LayoutAttributes(frame: .zero))
            .map { $0.node }

        XCTAssertEqual(children.count, 2)

        XCTAssertEqual(children[0].layoutAttributes, LayoutAttributes(frame: frame1))
        XCTAssertEqual(children[1].layoutAttributes, LayoutAttributes(frame: frame2))

        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize.zero), environment: .empty),
            CGSize(width: 600, height: 800))
    }
    
}

fileprivate struct MeasurableElement : Element {
    
    static var measureCount : Int = 0
    
    var content: ElementContent {
        ElementContent(measurementCachingKey: .init(type: Self.self, input: "element")) { constraint -> CGSize in
            Self.measureCount += 1
            return .init(width: 20.0, height: 20.0)
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        UIView.describe { _ in }
    }
}

fileprivate struct SimpleElement: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}


fileprivate struct FrameLayout: Layout {

    typealias Traits = CGRect

    func measure(in constraint: SizeConstraint, items: [(traits: CGRect, content: Measurable)]) -> CGSize {
        return items.reduce(into: CGSize.zero, { (result, item) in
            result.width = max(result.width, item.traits.maxX)
            result.height = max(result.height, item.traits.maxY)
        })
    }

    func layout(size: CGSize, items: [(traits: CGRect, content: Measurable)]) -> [LayoutAttributes] {
        return items.map { LayoutAttributes(frame: $0.traits) }
    }

    static var defaultTraits: CGRect {
        return CGRect.zero
    }

}
