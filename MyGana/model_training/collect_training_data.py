#!/usr/bin/env python3
"""
Data Collection Script for Japanese Character Recognition

This script helps you collect training data by capturing screenshots of handwritten
Japanese characters. It creates a simple interface where you can draw characters
and save them as training images.

Usage:
1. Run: python collect_training_data.py
2. Select a character to draw
3. Draw the character using your mouse
4. Press 's' to save the image
5. Press 'n' to go to next character
6. Press 'q' to quit

The images will be saved in the 'dataset' folder organized by character.
"""

import cv2
import numpy as np
import os
from collections import defaultdict

# Character labels
CHARACTER_LABELS = [
    # Hiragana
    'あ', 'い', 'う', 'え', 'お',
    'か', 'き', 'く', 'け', 'こ',
    'さ', 'し', 'す', 'せ', 'そ',
    'た', 'ち', 'つ', 'て', 'と',
    'な', 'に', 'ぬ', 'ね', 'の',
    'は', 'ひ', 'ふ', 'へ', 'ほ',
    'ま', 'み', 'む', 'め', 'も',
    'や', 'ゆ', 'よ',
    'ら', 'り', 'る', 'れ', 'ろ',
    'わ', 'を', 'ん',
    # Katakana
    'ア', 'イ', 'ウ', 'エ', 'オ',
    'カ', 'キ', 'ク', 'ケ', 'コ',
    'サ', 'シ', 'ス', 'セ', 'ソ',
    'タ', 'チ', 'ツ', 'テ', 'ト',
    'ナ', 'ニ', 'ヌ', 'ネ', 'ノ',
    'ハ', 'ヒ', 'フ', 'ヘ', 'ホ',
    'マ', 'ミ', 'ム', 'メ', 'モ',
    'ヤ', 'ユ', 'ヨ',
    'ラ', 'リ', 'ル', 'レ', 'ロ',
    'ワ', 'ヲ', 'ン',
]

class DataCollector:
    def __init__(self):
        self.current_char_index = 0
        self.drawing = False
        self.image = np.ones((400, 400, 3), dtype=np.uint8) * 255
        self.saved_count = defaultdict(int)
        
        # Create dataset directory
        os.makedirs("dataset", exist_ok=True)
        for char in CHARACTER_LABELS:
            os.makedirs(f"dataset/{char}", exist_ok=True)
    
    def mouse_callback(self, event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            self.drawing = True
        elif event == cv2.EVENT_MOUSEMOVE and self.drawing:
            cv2.circle(self.image, (x, y), 3, (0, 0, 0), -1)
        elif event == cv2.EVENT_LBUTTONUP:
            self.drawing = False
    
    def clear_image(self):
        self.image = np.ones((400, 400, 3), dtype=np.uint8) * 255
    
    def save_image(self):
        current_char = CHARACTER_LABELS[self.current_char_index]
        count = self.saved_count[current_char]
        
        # Resize to 64x64 for model input
        resized = cv2.resize(self.image, (64, 64))
        
        # Convert to grayscale
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        
        # Save image
        filename = f"dataset/{current_char}/sample_{count:03d}.png"
        cv2.imwrite(filename, gray)
        
        self.saved_count[current_char] += 1
        print(f"Saved {filename} (Total for {current_char}: {self.saved_count[current_char]})")
    
    def next_character(self):
        self.current_char_index = (self.current_char_index + 1) % len(CHARACTER_LABELS)
        self.clear_image()
    
    def run(self):
        cv2.namedWindow('Data Collection', cv2.WINDOW_AUTOSIZE)
        cv2.setMouseCallback('Data Collection', self.mouse_callback)
        
        print("Japanese Character Data Collection")
        print("=" * 40)
        print("Instructions:")
        print("- Draw the character shown below")
        print("- Press 's' to save the image")
        print("- Press 'n' to go to next character")
        print("- Press 'c' to clear current drawing")
        print("- Press 'q' to quit")
        print()
        
        while True:
            current_char = CHARACTER_LABELS[self.current_char_index]
            saved_count = self.saved_count[current_char]
            
            # Create display image with instructions
            display_img = self.image.copy()
            cv2.putText(display_img, f"Character: {current_char}", (10, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            cv2.putText(display_img, f"Saved: {saved_count}", (10, 60), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            cv2.putText(display_img, "Press 's' to save, 'n' for next, 'c' to clear, 'q' to quit", 
                       (10, 380), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
            
            cv2.imshow('Data Collection', display_img)
            
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('q'):
                break
            elif key == ord('s'):
                self.save_image()
            elif key == ord('n'):
                self.next_character()
            elif key == ord('c'):
                self.clear_image()
        
        cv2.destroyAllWindows()
        
        # Print summary
        print("\nData Collection Summary:")
        print("=" * 30)
        total_images = 0
        for char in CHARACTER_LABELS:
            count = self.saved_count[char]
            if count > 0:
                print(f"{char}: {count} images")
                total_images += count
        
        print(f"\nTotal images collected: {total_images}")
        print(f"Characters with data: {len([c for c in CHARACTER_LABELS if self.saved_count[c] > 0])}")

if __name__ == "__main__":
    collector = DataCollector()
    collector.run()

