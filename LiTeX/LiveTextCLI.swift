//
//  LiveTextCLI.swift
//  LiTeX
//
//  Created by MacBook Pro M1 on 2022/11/12.
//

import Foundation
import ArgumentParser
import Cocoa
import VisionKit
import Vision

@main
struct Litex: AsyncParsableCommand {
    static var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "litex",
        abstract: "Command line tool of Live Text",
        discussion: """
        LiTeX allows use Live Text as the command line tool and output results to a text file.
        """,
        version: "1.1.0",
        shouldDisplay: true
        )
    
    @Argument(help: "An image filepath.")
    var imagefilePath: String
}


// MARK: - Text recognition
extension Litex {
    func run() async throws {
        if #available(macOS 13.0, *) {
            try? await recognizeTextByLiveText()
        } else {
            // Fallback on earlier versions
            recognizeTextByVision()
        }
    }
    
    // MARK: - recognize text via ImageAnalyzer (Live Text)
    @available(macOS 13, *)
    func recognizeTextByLiveText() async throws {
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
                
                #if RELEASE
                // output to the text file
                let outputFilename = imageURL.deletingPathExtension().lastPathComponent + "_text.txt"
                let outputFilepath = imageURL.deletingLastPathComponent().appending(path: outputFilename)
                
                try? analysis.transcript.write(to: outputFilepath, atomically: true, encoding: .utf8)
                #endif
            } else {
                print("Text is not included in the image.")
            }
        }
    }
    
    // MARK: - recognize text via VNRecognizeTextRequest (Vision)
    func recognizeTextByVision() {
        // convert image filepath string to URL
        let imageURL = URL(fileURLWithPath: imagefilePath)
        
        let nsImage = NSImage(contentsOf: imageURL)
        guard let cgImage = nsImage?.cgImage else { return }
        
        // setup request
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
            
            // output to the text file
            let recognizedText = recognizedStrings.joined(separator: "\n")
            print(recognizedText)
            
            #if RELEASE
            let outputFilename = imageURL.deletingPathExtension().lastPathComponent + "_text.txt"
            let outputFilepath = imageURL.deletingLastPathComponent().appendingPathComponent(outputFilename)
            
            try? recognizedText.write(to: outputFilepath, atomically: true, encoding: .utf8)
            #endif
        })
        
        // perform
        do {
            #if DEBUG
            let supportedLanguages = try request.supportedRecognitionLanguages()
            print("⚙️ Supported Languages: \(supportedLanguages)")
            let recognitionLanguages = request.recognitionLanguages
            print("⚙️ Recognized Languages: \(recognitionLanguages)")
            #endif
            
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
}
