// ARModel+Resolved.swift
// Adds missing helpers used by ARViewContainer

import Foundation

// This extension provides the APIs used in ARViewContainer:
// - resolvedURL(): URL
// - resolvedKind: Kind
// It makes minimal assumptions about ARModel's shape. If ARModel already
// has differently named properties for its source, update the mapping below.

extension ARModel {
    enum Kind {
        case usdz
        case reality
        case other
    }

    /// ARModel が保持する fileURL を返します。
    /// 無効な URL の場合は URLError(.badURL) を投げます。
    func resolvedURL() throws -> URL {
        if let url = self.fileURL {
            return url
        }
        throw URLError(.badURL)
    }

    /// URL の拡張子、もしくは補助プロパティから種別を判定します。
    var resolvedKind: Kind {
        if self.isUSDZ { return .usdz }
        if self.isReality { return .reality }
        // 最後の手段として拡張子で判定
        if let ext = self.fileURL?.pathExtension.lowercased() {
            switch ext {
            case "usdz": return .usdz
            case "reality": return .reality
            default: break
            }
        }
        return .other
    }
}
