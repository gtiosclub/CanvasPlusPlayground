#!/bin/sh

#  ci_post_clone.sh
#  CanvasPlusPlayground
#
#  Created by Rahul on 3/31/25.
#  

# Allow swiftlint and MLX to be validated for Xcode Cloud
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
