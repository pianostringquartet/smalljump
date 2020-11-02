//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI

func coloredCircle(color: Color, radius: CGFloat) -> some View {
    LinearGradient(gradient: Gradient(colors: [.white, color]),
                   startPoint: .topLeading,
                   endPoint: .bottomTrailing)
        .frame(width: radius, height: radius)
        .clipShape(Circle())
}

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}
    
// A ball that stays where you drag it
struct DraggableBall: View {
    
    // how far displaced in given gesture
    @State private var position = CGSize.zero
    
    @State private var previousPosition = CGSize.zero
        
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: color, radius: radius)
            
            // move ball as we drag
            .offset(x: self.position.width, y: self.position.height)
            
            // alternatively: move ball only after we let go
//            .offset(x: self.previousPosition.width, y: self.previousPosition.height)
            
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            
            // give ball some bounce
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


// A ball that bounces back to its original position
struct BoomerangBall: View {
    
    @State private var position = CGSize.zero
    
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: .black, radius: 125)
        .offset(position)
        .gesture(DragGesture()
                    .onChanged { self.position = $0.translation }
                    .onEnded { _ in
                        withAnimation(.spring()) { self.position = .zero }
                    })
    }
}


struct StrangeShape: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 50, y: 100))
            path.addLine(to: CGPoint(x: 50, y: 300))
            path.addLine(to: CGPoint(x: 150, y: 190))
            path.addLine(to: CGPoint(x: 120, y: 120))
        }
    }
}

// Extending CGPoint to work with VectorArithmetic, needded
extension CGPoint: VectorArithmetic {
    public static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
    
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    public mutating func scale(by rhs: Double) {
        x *= CGFloat(rhs)
        y *= CGFloat(rhs)
    }
    
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public var magnitudeSquared: Double { return Double(x*x + y*y) }
}

// same as EdgeShape used here: https://gist.github.com/chriseidhof/d23f82f8a9e85e75bc02be220326199a
struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    var animatableData: AnimatablePair<CGPoint, CGPoint> {
        get { AnimatablePair(from, to) }
        set {
            from = newValue.first
            to = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

class Unique<A>: Identifiable {
    let value: A
    init(_ value: A) { self.value = value }
}

extension Unique: Equatable where A: Equatable {
    static func == (lhs: Unique<A>, rhs: Unique<A>) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
extension Unique: Hashable where A: Hashable {
    func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }
}




// defining a data type for a preference data
struct MyAnchorPreferenceData {
//    let bounds: Anchor<CGRect>
    let viewIdx: Int
    let center: Anchor<CGPoint>
}

// a preference key for preference data; we're using just a list
struct MyAnchorPreferenceKey: PreferenceKey {
    typealias Value = [MyAnchorPreferenceData]
    
    // for if a child doesn't define preferences
    static var defaultValue: [MyAnchorPreferenceData] = []
    
    // how to tak a new datum, and add it to the existing preference data
    static func reduce(value: inout [MyAnchorPreferenceData], nextValue: () -> [MyAnchorPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
    
}


struct EdgeBall: View {
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
        
    let idx: Int
    
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: color, radius: radius)
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            
//            modeled on: https://swiftui-lab.com/communicating-with-the-view-tree-part-2/
//            .anchorPreference(key: MyAnchorPreferenceKey.self,
//                              value: .center, // center for CGPoint
//                              transform: { [MyAnchorPreferenceData(viewIdx: self.idx, center: $0)] })
            
            // the child will set its anchor preference data,
//          i.e. it will give back its own .center point
//            .anchorPreference(key: MyAnchorPreferenceKey.self,
//                              value: .center, // center for CGPoint
//                              transform: { [MyAnchorPreferenceData(viewIdx: self.idx, center: $0)] })
    }
}


struct ContentView: View {
    
    @State private var activeIdx: Int = 0
    
    @State private var cgp0: CGPoint = CGPoint(x: 100, y: 200)
    @State private var cgp1: CGPoint = CGPoint(x: 200, y: 100)
    
    
    @State private var position: CGSize = CGSize.zero
    @State private var previousPosition: CGSize = CGSize.zero
    let color: Color = Color.green
    let radius: CGFloat = 50
    
    @State private var position1 = CGSize.zero
    @State private var previousPosition1 = CGSize.zero
    let color1 = Color.blue
    let radius1: CGFloat = 75
    
    
    
    // for easier visibility of edges
    private var spacing: CGFloat = 50
    var body: some View {
        VStack (spacing: spacing) {
//            BoomerangBall(color: .black, radius: 125)
//            DraggableBall(color: .red, radius: 100)
//            DraggableBall(color: .blue, radius: 75)
//            DraggableBall(color: .green, radius: 50)
            
            // .map(Unique.init)
            EdgeBall(idx: 0, color: .purple, radius: 75).onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                self.cgp1 = CGPoint(x: 50, y: 75)
            })
            EdgeBall(idx: 1, color: .pink, radius: 50).onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                self.cgp0 = CGPoint(x: 150, y: 170)
            })
            
//            Line(from: cgp0, to: cgp1).stroke()
            
            // can create something better...
//            Line(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 200, y: 100)).stroke()
            
            
        
            coloredCircle(color: color, radius: radius)
                    .anchorPreference(key: MyAnchorPreferenceKey.self,
                              value: .center, // center for CGPoint
                              transform: { [MyAnchorPreferenceData(viewIdx: 0, center: $0)] })
                    .offset(x: self.position.width, y: self.position.height)
                    .gesture(DragGesture()
                                .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                                .onEnded { _ in self.previousPosition = self.position })
                    .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
                    
                
            
            
            coloredCircle(color: color1, radius: radius1)
                        .anchorPreference(key: MyAnchorPreferenceKey.self,
                          value: .center, // center for CGPoint
                          transform: { [MyAnchorPreferenceData(viewIdx: 1, center: $0)] })
                        .offset(x: self.position1.width, y: self.position1.height)
                        .gesture(DragGesture()
                                    .onChanged { self.position1 = updatePosition(value: $0, position: self.previousPosition1) }
                                    .onEnded { _ in self.previousPosition1 = self.position1 })
                        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
                        
            
//            position.
            
            
            
            // this line works, and changes as we drag the balls
//            Line(from: CGPoint(x: position.width, y: position.height),
//                 to: CGPoint(x: position1.width, y: position1.height))
//                .stroke()
            
            // however, the alignment is bad
            //
         
//            GeometryReader { geometry in
//
//                let globalMidX = geometry.frame(in: .global).midX
//                let globalMidY = geometry.frame(in: .global).midY
//
//                let gp = CGPoint(x: globalMidX, y: geometry.frame(in: .global).midY)
//                let gpTop = CGPoint(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
//
//
//                Line(from: gp, to: gpTop).stroke().animation(.default)
//
////                let point0 = geometry[position]
////                let point1 = geometry[position1]
////
////                Line(from: point0, to: point1).stroke().animation(.default)
//            }
            
        }
        
        // works BUT DOES NOT DETECT MOVEMENT OF BALLS
        .backgroundPreferenceValue(MyAnchorPreferenceKey.self) { preferences in
            return GeometryReader { geometry in
                
//                let p0 = preferences.first(where: { $0.viewIdx == 0})
//                let p1 = preferences.first(where: { $0.viewIdx == 1})
//                let point0 = geometry[p0!.center]
//                let point1 = geometry[p1!.center]
                
                let p0 = preferences[0]
                let p1 = preferences[1]
                // the ! is an unwrapped from an optional type?
                let point0 = geometry[p0.center]
                let point1 = geometry[p1.center]
                Line(from: point0, to: point1).stroke().animation(.default)
            }
        }
    }
    
//    func createBorder(_ geometry: GeometryProxy, _ preferences: [MyAnchorPreferenceData]) -> some View {
//
//    // here we grabbed just the ACTIVE month preference
//            let p = preferences.first(where: { $0.viewIdx == self.activeIdx })
//
    // // then we check, as long as p isn't nil, use
//            let bounds = p != nil ? geometry[p!.bounds] : .zero
//
//            return RoundedRectangle(cornerRadius: 15)
//                    .stroke(lineWidth: 3.0)
//                    .foregroundColor(Color.green)
//                    .frame(width: bounds.size.width, height: bounds.size.height)
//                    .fixedSize()
//                    .offset(x: bounds.minX, y: bounds.minY)
//                    .animation(.easeInOut(duration: 1.0))
//        }
    
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
