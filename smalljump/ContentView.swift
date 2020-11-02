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

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
//    var animatableData: AnimatablePair<CGPoint, CGPoint> {
//        get { AnimatablePair(from, to) }
//        set {
//            from = newValue.first
//            to = newValue.second
//        }
//    }

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
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
            
            // the child will set its anchor preference data,
//          i.e. it will give back its own .center point
            .anchorPreference(key: MyAnchorPreferenceKey.self,
                              value: .center, // center for CGPoint
                              transform: { [MyAnchorPreferenceData(viewIdx: self.idx, center: $0)] })
    }
}


struct ContentView: View {
    
    @State private var activeIdx: Int = 0
    
    // for easier visibility of edges
    private var spacing: CGFloat = 50
    var body: some View {
        VStack (spacing: spacing) {
//            BoomerangBall(color: .black, radius: 125)
//            DraggableBall(color: .red, radius: 100)
//            DraggableBall(color: .blue, radius: 75)
//            DraggableBall(color: .green, radius: 50)
            
            EdgeBall(idx: 0, color: .purple, radius: 75)
            EdgeBall(idx: 1, color: .pink, radius: 50)
            
            // can create something better...
//            Line(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 200, y: 100)).stroke()
//            StrangeShape()
        }.backgroundPreferenceValue(MyAnchorPreferenceKey.self) { preferences in
            return GeometryReader { geometry in
//                ForEach(preferences )
                
                // preferences is the PreferencesKeyData, no?
                
//                Line
                
                let p0 = preferences.first(where: { $0.viewIdx == 0})
                let p1 = preferences.first(where: { $0.viewIdx == 1})
//
                
                let point0 = geometry[p0!.center]
                let point1 = geometry[p1!.center]
                
                Line(from: point0, to: point1).stroke()
                
//                return Line(from: preferences[0], to: preferences[1]).stroke()
                
                
//                self.createBorder(geometry, preferences)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
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
