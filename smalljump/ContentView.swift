//
//  ContentView.swift
//  smalljump
//
//  Created by cjc on 10/31/20.
//

import SwiftUI
import AVFoundation

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

var audioPlayer: AVAudioPlayer?

//let path = Bundle.main.path(forResource: "example.mp3", ofType: nil)
//let url = URL(fileURLWithPath: path)

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) { // or?: `ofType: type`
        do {
            log("Will try to play sound")
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            log("Unable to play sound")
        }
    }
}


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
//    let isEnabled: Bool
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
 DOMAIN TYPES: representations of domain concepts
 ---------------------------------------------------------------- */

struct Connection: Identifiable {
    let id: UUID = UUID()
    let from: Int
    let to: Int
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

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}


struct Ball: View {
    
    // ie balls start out at .zero
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
        
    @Binding public var connections: [Connection]
    @Binding public var nodeCount: Int
    
    let nodeNumber: Int
    let radius: CGFloat
    
    init(nodeNumber: Int, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>) {
        self.nodeNumber = nodeNumber
        self.radius = radius
        self._connections = connections
        self._nodeCount = nodeCount
    }
     
    func determineColor() -> Color {
        return !isAnchored ? .blue : Color.gray.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
    }
    
    var body: some View {
//      LinearGradient(gradient: Gradient(colors: [.white, isAnchored ? .gray : .blue,]),
        LinearGradient(gradient: Gradient(colors: [.white, determineColor()]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
//          .frame(width: radius, height: radius) // PREVIOUSLY
            .clipShape(Circle())
            .background(Image(systemName: "plus"))
            
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { (value: DragGesture.Value) in
    //                            self.position = updatePosition(value: $0, position: self.previousPosition)
                            self.position = updatePosition(value: value, position: self.previousPosition)
                        }
                        .onEnded { (value: DragGesture.Value) in
                            
                            log("onEnded: value.translation: \(value.translation)");
    //                        log("onEnded: isAnchored: \(isAnchored)")
    //                        log("onEnded: nodeCount: \(nodeCount)")
                            if isAnchored { // only care about minDistance etc. if Anchorded
//                                let minDistance: CGFloat = CGFloat(100)
                                let minDistance: CGFloat = CGFloat(90)
                                let movedEnough: Bool =
                                    abs(value.translation.width) > minDistance ||
                                    abs(value.translation.height) > minDistance
                                if movedEnough {
                                    log("moved enough")
                                    self.isAnchored.toggle()
                                    self.previousPosition = self.position
                                    
                                    // ball was anchored, but was moved enough to become regular ball
                                    // so we now need a new ball

                                    log("nodeCount was: \(nodeCount)")
                                    self.nodeCount += 1
                                    log("nodeCount is now: \(nodeCount)")
                                    log("idx is: \(nodeNumber)")
                                    playSound(sound: "positive_ping", type: "mp3")
                                }
                                else {
                                    log("did not move enough");
                                    withAnimation(.spring()) { self.position = .zero }
                                }
                            }
                            else {
                                log("is not anchored; will let move freely");
                                self.previousPosition = self.position }
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .frame(width: radius, height: radius)
    }
}



/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

func textOrNil(_ text: Bool) -> Text? {
    guard text else { return nil }
    return Text("Hello")
}

func imageOrNil(_ text: Bool) -> Image? {
    guard text else { return Image(systemName: "headphones") }
    return nil
}


struct ContentView: View {
    // always want at least 1 node!
    @State private var nodeCount: Int = 1
    
    // all existings edges
    @State public var connections: [Connection] = []

    // everytime the data changes, this exact code is run again with the data
    var body: some View {
        ZStack {
            log("nodeCount: \(nodeCount)")
            
            ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
                Ball(nodeNumber: nodeNumber,
                    radius: 40,
                    connections: $connections,
                    nodeCount: $nodeCount)
            }
            
        }
        // do nothing for now
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
//            if connections.count >= 1 && nodeCount >= 2 {
//                GeometryReader { (geometry: GeometryProxy) in
//                    ForEach(connections, content: { (connection: Connection) in
//                        let toPref: BallPreferenceData = preferences[connection.to]
//                        let fromPref: BallPreferenceData = preferences[connection.from]
//                        if toPref.isEnabled && fromPref.isEnabled {
//                            line(from: geometry[toPref.center],
//                                 to: geometry[fromPref.center])
//                        }
//                    })
//                }
//            }
        }
    }
}
    


/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
