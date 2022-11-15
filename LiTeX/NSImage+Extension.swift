//
//  NSImage+Extension.swift
//  litex
//
//  Created by MacBook Pro M1 on 2022/11/15.
//

import Cocoa

// MARK: - NSImage extension
// https://qiita.com/HaNoHito/items/2fe95aba853f9cedcd3e
extension NSImage {
    var cgImage: CGImage {
        var imageRect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        #if swift(>=3.0)
        guard let image =  cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            abort()
        }
        #else
        guard let image = CGImageForProposedRect(&imageRect, context: nil, hints: nil) else {
            abort()
        }
        #endif
        return image
    }
}
