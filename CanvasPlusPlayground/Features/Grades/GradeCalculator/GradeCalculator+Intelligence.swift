//
//  GradeCalculator+Intelligence.swift
//  CanvasPlusPlayground
//
//  Created by Rahul on 3/29/25.
//

import SwiftUI

extension GradeCalculator {
    /// Indicates whether this Course would benefit by using Intelligence.
    /// e.g. if groups are unweighted or there are no assignment groups.
    var canUseIntelligenceAssistance: Bool {
        !gradeGroups.isEmpty && gradeGroups.reduce(0.0) { $0 + $1.weight } == 0.0
    }
}
