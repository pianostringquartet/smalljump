//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
//struct BallPreferenceData {
//    let viewIdx: Int
//    let center: Anchor<CGPoint>
//}

// add Identifiable, so can use in ForEach?
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
}


// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]
    
    static var defaultValue: [BallPreferenceData] = []
    
    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
    
}


/* ----------------------------------------------------------------
 UI ELEMENTS: draggable balls, etc.
 ---------------------------------------------------------------- */

struct Line: Shape {
    let from, to: CGPoint
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

func line(from: CGPoint, to: CGPoint) -> some View {
    Line(from: from, to: to).stroke().animation(.default)
}


struct IdLine: Shape, Identifiable {
    
    var id = UUID()
    
    let from, to: CGPoint
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

func idLine(from: CGPoint, to: CGPoint) -> some View {
    IdLine(from: from, to: to).stroke().animation(.default)
}


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
 

// struct EdgeBall: View, Equatable {
struct EdgeBall: View, Identifiable {
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    
    let id = UUID()
    
    let idx: Int
    let color: Color
    let radius: CGFloat
    
    // add for equatable; also probably need more
//    static func == (lhs: EdgeBall, rhs: EdgeBall) -> Bool {
//           lhs.idx == rhs.idx
//       }
    
    
    var body: some View {
        coloredCircle(color: color, radius: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.idx, center: $0)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

 
struct ContentView: View {
    
    @State private var ballCount = 3
    
    let spacing: CGFloat = 25 //100
    
    // want a variable here for counting nodes?
    // and then a 'ForEach' ? with color and size randomly assigned
    
    // will need to make node connections occur programmatically;
    // why can't you do e.g. ForEach { Line... } ?
    // or even preferences.forEach(...)
    // ... you're gonna be drawing a
    
    // need to start `isActive` information in PreferenceData too?
    
    
    // dict of {
    
    var body: some View {
        VStack (spacing: spacing) {
//            EdgeBall(idx: 0, color: .purple, radius: 75)
//            HStack (spacing: spacing) {
//                EdgeBall(idx: 1, color: .pink, radius: 50)
//                EdgeBall(idx: 2, color: .green, radius: 75)
//            }
//            EdgeBall(idx: 3, color: .blue, radius: 50)
            
            log("testing...")
            log("yes we're testing...")
            
//            ForEach(0 ..< ballCount, id: \.self) { count in
            ForEach(0 ..< ballCount, id: \.self) { count -> EdgeBall in
                // need to get idxs via enumeration
//                EdgeBall(idx: 0, color: .red, radius: 25)
//                print("ForEach ballcount run")
                log("inside ForEach ballcount: count: \(count)")
                return EdgeBall(idx: count, color: .red, radius: 25)
            }
            Button(action: {
                self.ballCount += 1
            }) {
                Text("Create node")
            }
            Button(action: {
                self.ballCount -= 1
            }) {
                Text("Remove node")
            }
            
        }
        
        // TODO: make a separate function that returns a ViewModifier?
        .backgroundPreferenceValue(BallPreferenceKey.self) { preferences in
            // check: is the preference length increasing?
            
//            let _ = print("in backgroundPreferenceValue...")
            
//            print("backgroundPreferenceValue: preferences: \(preferences)")
            
            
            return GeometryReader { geometry in
                
                // This does not seem to be rerun when the `ballCount` is updated
                // issue does not seem to be ids etc, because draw
                
//                print("in GeometryReader...")
//                return ForEach(preferences.indices, content: { prefIdx in
                
                
                // some thoughts?:
                // 1. ForEach might not be appropriate for non-Views like Preferences or even indices?
                // 2. I might need to use a collection that has the 'identifiable' property?
                
//                return ForEach(preferences.indices, content: { prefIdx in
                
                return ForEach(preferences, content: { pref in
                    
                    log("inside ForEach preferences.indices ...")
                    log("preferences.indices: \(preferences.indices)")
                    log("preferences.count: \(preferences.count)")
                    log("pref: \(pref)")
                    
                    if preferences.count >= 2 {
////                        log("We have enough nodes to draw a line")
//                        let point0 = geometry[preferences[0].center]
////                        log("pref.viewIdx: \(pref.viewIdx)")
//                        let myPointPref = preferences[pref.viewIdx] //firstIndex(where { $0.idx == } )
////                        log("myPointPref: \(myPointPref)")
//                        let myPoint = geometry[myPointPref.center]
////                        log("myPoint: \(myPoint)")
//
                        // TODO: Create edges between 'enabled' balls,
                        // not between each ball and  'origin' ball
//                        let origin = geometry[preferences[0].center]
//                        let myPoint = geometry[myPointPref.center]
                        line(from: geometry[preferences[0].center],
                             to: geometry[preferences[pref.viewIdx].center])
//                        line(from: point0, to: myPoint)
                    }
//                    else {
//                        log("We DID NOT have enough nodes to draw a line")
//                    }

                })
            }}
                
                
//                ForEach(preferences.indices, content: { prefIdx in
//                    let point0 = geometry[preferences[0].center]
//                    let thisPoint = geometry[preferences[prefIdx].center]
//                    idLine(from: thisPoint, to: point0)
//                })
                
                
                // TODO: cleaner, programmatic construction of edges
//                let point0 = geometry[preferences[0].center]
//                let point1 = geometry[preferences[1].center]
//                let point2 = geometry[preferences[2].center]
//                let point3 = geometry[preferences[3].center]
//                line(from: point0, to: point1)
//                line(from: point1, to: point2)
//                line(from: point2, to: point3)
//                line(from: point0, to: point3)
//                line(from: point1, to: point3)
//            }
//        }
    }
}

struct MyRectView: View {
    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 200, height: 200)
    }
}

struct RootView: View {
    @State private var numberOfRects = 0

    var body: some View {
        VStack {
            Button(action: {
                self.numberOfRects += 1
            }) {
                Text("Tap to create")
            }
            ForEach(0 ..< numberOfRects, id: \.self) { _ in
                MyRectView()
            }
        }
    }
}

/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
//        RootView()
    }
}
