//
//  StampManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import SwiftUI

/// A class to manage saving, loading, and holding stamp data.
class StampManager: ObservableObject {
    /// The array of collected stamps, published for UI updates.
    @Published var stamps: [Stamp] = []
    
    private let stampsDirectoryURL: URL
    private let stampsJSONURL: URL
    
    init() {
        // Get the URL for the user's documents directory.
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create a dedicated directory for stamp images.
        stampsDirectoryURL = documentsURL.appendingPathComponent("StampImages")
        // Define the URL for the JSON file that stores the list of stamps.
        stampsJSONURL = documentsURL.appendingPathComponent("stamps.json")
        
        // Create the directory if it doesn't exist.
        try? FileManager.default.createDirectory(at: stampsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        // Load existing stamps when the manager is initialized.
        loadStamps()
    }
    
    /// Adds a new stamp by saving the image and updating the stamp list.
    /// - Parameter image: The UIImage to be saved as a stamp.
    func addStamp(image: UIImage) {
        // Generate a unique filename for the image.
        let fileName = UUID().uuidString + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        // Convert the image to JPEG data.
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data.")
            return
        }
        
        do {
            // Write the image data to the file URL.
            try data.write(to: fileURL)
            
            // Create a new Stamp object.
            let newStamp = Stamp(id: UUID(), imageFileName: fileName, acquiredDate: Date())
            
            // Add the new stamp to the array and save the updated list.
            stamps.append(newStamp)
            saveStamps()
            print("スタンプを保存しました: \(fileName)")
        } catch {
            print("画像の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// Saves the current array of stamps to a JSON file.
    private func saveStamps() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stamps)
            try data.write(to: stampsJSONURL)
        } catch {
            print("スタンプリストの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// Loads the array of stamps from the JSON file.
    private func loadStamps() {
        guard let data = try? Data(contentsOf: stampsJSONURL) else { return }
        
        do {
            let decoder = JSONDecoder()
            stamps = try decoder.decode([Stamp].self, from: data)
        } catch {
            print("スタンプリストの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves a UIImage for a given stamp.
    /// - Parameter stamp: The stamp for which to load the image.
    /// - Returns: A UIImage if found, otherwise nil.
    func getImage(for stamp: Stamp) -> UIImage? {
        let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }
}
