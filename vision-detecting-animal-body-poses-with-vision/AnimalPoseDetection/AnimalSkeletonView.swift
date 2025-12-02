/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's skeleton view, which connects the joint landmarks to draw the skeleton of the animal.
*/

import SwiftUI

struct AnimalSkeletonView: View {
    // Get the animal joint locations.
    @StateObject var animalJoint = AnimalPoseDetector()
    var size: CGSize
    var body: some View {
        DisplayView(animalJoint: animalJoint)
        if animalJoint.animalBodyParts.isEmpty == false {
            // Draw the skeleton of the animal.
            // Iterate over all recognized points and connect the joints.
            ZStack {
                ZStack {
                    // left head
                    if let nose = animalJoint.animalBodyParts[.nose] {
                        if let leftEye = animalJoint.animalBodyParts[.leftEye] {
                            Line(points: [nose.location, leftEye.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.orange)
                        }
                    }
                    if let leftEye = animalJoint.animalBodyParts[.leftEye] {
                        if let leftEarBottom = animalJoint.animalBodyParts[.leftEarBottom] {
                            Line(points: [leftEye.location, leftEarBottom.location], size: size)
                                .stroke(lineWidth: 5.0)
                                .fill(Color.orange)
                        }
                    }
                    if let leftEarBottom = animalJoint.animalBodyParts[.leftEarBottom] {
                        if let leftEarMiddle = animalJoint.animalBodyParts[.leftEarMiddle] {
                            if let leftEarTop = animalJoint.animalBodyParts[.leftEarTop] {
                                    Line(points: [leftEarBottom.location, leftEarMiddle.location,
                                                  leftEarTop.location], size: size)
                                                        .stroke(lineWidth: 5.0)
                                                        .fill(Color.orange)
                            }
                        }
                    }
                    // right head
                    if let nose = animalJoint.animalBodyParts[.nose] {
                        if let rightEye = animalJoint.animalBodyParts[.rightEye] {
                            Line(points: [nose.location, rightEye.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.orange)
                        }
                    }
                    if let rightEye = animalJoint.animalBodyParts[.rightEye] {
                        if let rightEarBottom = animalJoint.animalBodyParts[.rightEarBottom] {
                            Line(points: [rightEye.location, rightEarBottom.location], size: size)
                                .stroke(lineWidth: 5.0)
                                .fill(Color.orange)
                        }
                    }
                    if let rightEarBottom = animalJoint.animalBodyParts[.rightEarBottom] {
                        if let rightEarMiddle = animalJoint.animalBodyParts[.rightEarMiddle] {
                            if let rightEarTop = animalJoint.animalBodyParts[.rightEarTop] {
                                    Line(points: [rightEarBottom.location, rightEarMiddle.location,
                                          rightEarTop.location], size: size)
                                        .stroke(lineWidth: 5.0)
                                        .fill(Color.orange)
                            }
                        }
                    }
                    // trunk - Draw a line from the nose to the neck.
                    if let nose = animalJoint.animalBodyParts[.nose] {
                        if let neck = animalJoint.animalBodyParts[.neck] {
                            Line(points: [nose.location, neck.location], size: size)
                                .stroke(lineWidth: 5.0)
                                .fill(Color.yellow)
                        }
                    }
                    // tail - Draw a line from the neck to the bottom tail.
                    if let neck = animalJoint.animalBodyParts[.neck] {
                        if let tailBottom = animalJoint.animalBodyParts[.tailBottom] {
                            Line(points: [neck.location,
                                          tailBottom.location], size: size)
                                        .stroke(lineWidth: 5.0)
                                        .fill(Color.green)
                        }
                    }
                }
                ZStack {
                    // left forelegs
                    if let neck = animalJoint.animalBodyParts[.neck] {
                        if let leftFrontElbow = animalJoint.animalBodyParts[.leftFrontElbow] {
                            Line(points: [neck.location, leftFrontElbow.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.purple)
                        }
                    }
                    if let leftFrontElbow = animalJoint.animalBodyParts[.leftFrontElbow] {
                        if let leftFrontKnee = animalJoint.animalBodyParts[.leftFrontKnee] {
                            if let leftFrontPaw = animalJoint.animalBodyParts[.leftFrontPaw] {
                                Line(points: [leftFrontElbow.location, leftFrontKnee.location, leftFrontPaw.location], size: size)
                                    .stroke(lineWidth: 5.0)
                                    .fill(Color.purple)
                            }
                        }
                    }
                    // right forelegs
                    if let neck = animalJoint.animalBodyParts[.neck] {
                        if let rightFrontElbow = animalJoint.animalBodyParts[.rightFrontElbow] {
                            Line(points: [neck.location, rightFrontElbow.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.purple)
                        }
                    }
                    if let rightFrontElbow = animalJoint.animalBodyParts[.rightFrontElbow] {
                        if let rightFrontKnee = animalJoint.animalBodyParts[.rightFrontKnee] {
                            if let rightFrontPaw = animalJoint.animalBodyParts[.rightFrontPaw] {
                                Line(points: [rightFrontElbow.location, rightFrontKnee.location, rightFrontPaw.location], size: size)
                                    .stroke(lineWidth: 5.0)
                                    .fill(Color.purple)
                            }
                        }
                    }
                    // left hindlegs
                    if let tailBottom = animalJoint.animalBodyParts[.tailBottom] {
                        if let leftBackElbow = animalJoint.animalBodyParts[.leftBackElbow] {
                            Line(points: [tailBottom.location, leftBackElbow.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.blue)
                        }
                    }
                    if let leftBackElbow = animalJoint.animalBodyParts[.leftBackElbow] {
                        if let leftBackKnee = animalJoint.animalBodyParts[.leftBackKnee] {
                            if let leftBackPaw = animalJoint.animalBodyParts[.leftBackPaw] {
                                Line(points: [leftBackElbow.location, leftBackKnee.location, leftBackPaw.location], size: size)
                                    .stroke(lineWidth: 5.0)
                                    .fill(Color.blue)
                            }
                        }
                    }
                    // right hindlegs
                    if let tailBottom = animalJoint.animalBodyParts[.tailBottom] {
                        if let rightBackElbow = animalJoint.animalBodyParts[.rightBackElbow] {
                            Line(points: [tailBottom.location, rightBackElbow.location], size: size)
                            .stroke(lineWidth: 5.0)
                            .fill(Color.blue)
                        }
                    }
                    if let rightBackElbow = animalJoint.animalBodyParts[.rightBackElbow] {
                        if let rightBackKnee = animalJoint.animalBodyParts[.rightBackKnee] {
                            if let rightBackPaw = animalJoint.animalBodyParts[.rightBackPaw] {
                                Line(points: [rightBackElbow.location, rightBackKnee.location, rightBackPaw.location], size: size)
                                    .stroke(lineWidth: 5.0)
                                    .fill(Color.blue)
                            }
                        }
                    }
                }
                ZStack {
                    // Connect the tail joints.
                    if let tailBottom = animalJoint.animalBodyParts[.tailBottom] {
                        if let tailMiddle = animalJoint.animalBodyParts[.tailMiddle] {
                            if let tailTop = animalJoint.animalBodyParts[.tailTop] {
                                Line(points: [tailBottom.location, tailMiddle.location, tailTop.location], size: size)
                                    .stroke(lineWidth: 5.0)
                                    .fill(Color.orange)
                            }
                        }
                    }
                }
            }
        }
    }
}
// Create a transform that converts the pose's normalized point.
struct Line: Shape {
    var points: [CGPoint]
    var size: CGSize
    func path(in rect: CGRect) -> Path {
        let pointTransform: CGAffineTransform =
            .identity
            .translatedBy(x: 0.0, y: -1.0)
            .concatenating(.identity.scaledBy(x: 1.0, y: -1.0))
            .concatenating(.identity.scaledBy(x: size.width, y: size.height))
        var path = Path()
        path.move(to: points[0])
        for point in points {
            path.addLine(to: point)
        }
        return path.applying(pointTransform)
    }
}
