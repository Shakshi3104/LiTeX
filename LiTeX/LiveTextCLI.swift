//
//  main.swift
//  LiTeX
//
//  Created by MacBook Pro M1 on 2022/11/12.
//

import Foundation
import ArgumentParser
import Cocoa
import VisionKit

@main
struct LiveTextPlayground: AsyncParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "litex",
        abstract: "Command line tool of Live Text",
        discussion: """
        LiTeX allows use Live Text as the command line tool and output results to a text file.
        """,
        version: "1.0.0",
        shouldDisplay: true
        )
    
    @Argument(help: "An image filepath.")
    var imagefilePath: String
}

extension LiveTextPlayground {
    func run() async throws {
        #if DEBUG
        print("⚙️ Live Text Supported: \(ImageAnalyzer.isSupported)")
        print("⚙️ Supported Languages: \(ImageAnalyzer.supportedTextRecognitionLanguages)")
        #endif
        
        // if not supported
        if !ImageAnalyzer.isSupported {
            print("Live Text is not supported in this Mac.")
            return
        }
        
        // convert image filepath string to URL
        let imageURL = URL(filePath: imagefilePath)
        
        // setup ImageAnalyzer
        let configuration = ImageAnalyzer.Configuration([.text])
        let analyzer = ImageAnalyzer()
        
        // analyze the image
        let analysis = try? await analyzer.analyze(imageAt: imageURL,
                                                   orientation: .up,
                                                   configuration: configuration)
        // output results
        if let analysis {
            #if DEBUG
            print("⚙️ hasResults: \(analysis.hasResults(for: .text))")
            #endif
            
            if analysis.hasResults(for: .text) {
                print(analysis.transcript)
                
                // output to the text file
                let outputFilename = imageURL.deletingPathExtension().lastPathComponent + "_text.txt"
                let outputFilepath = imageURL.deletingLastPathComponent().appending(path: outputFilename)
                
                try? analysis.transcript.write(to: outputFilepath, atomically: true, encoding: .utf8)
            } else {
                print("Text is not included in the image.")
            }
        }
    }
}
