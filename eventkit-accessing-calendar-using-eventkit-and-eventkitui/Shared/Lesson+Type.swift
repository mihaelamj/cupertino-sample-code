/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The type of a lesson.
*/

import Foundation

/// Defines the type of a lesson.
enum LessonType: Int, Hashable, CaseIterable, Identifiable, Codable {
    var id: Int { rawValue }
    
    case single = 1
    case recurring = 2
}
