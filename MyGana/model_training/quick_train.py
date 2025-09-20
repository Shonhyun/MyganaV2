#!/usr/bin/env python3
"""
Quick training script for Japanese character recognition
This is a simplified version that trains faster
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split

# Model configuration
INPUT_SIZE = 64
NUM_CLASSES = 92  # 46 Hiragana + 46 Katakana
BATCH_SIZE = 32
EPOCHS = 10  # Reduced epochs for faster training
LEARNING_RATE = 0.001

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

def load_dataset(data_dir):
    """Load and preprocess the dataset"""
    images = []
    labels = []
    
    print("Loading dataset...")
    
    for i, char in enumerate(CHARACTER_LABELS):
        char_dir = os.path.join(data_dir, char)
        if not os.path.exists(char_dir):
            print(f"Warning: Directory {char_dir} not found, skipping character {char}")
            continue
            
        for filename in os.listdir(char_dir):
            if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
                img_path = os.path.join(char_dir, filename)
                try:
                    # Load and preprocess image
                    img = tf.keras.preprocessing.image.load_img(
                        img_path, 
                        color_mode='grayscale', 
                        target_size=(INPUT_SIZE, INPUT_SIZE)
                    )
                    img_array = tf.keras.preprocessing.image.img_to_array(img)
                    img_array = img_array / 255.0  # Normalize to [0, 1]
                    
                    images.append(img_array)
                    labels.append(i)
                except Exception as e:
                    print(f"Error loading {img_path}: {e}")
                    continue
    
    print(f"Loaded {len(images)} images for {len(set(labels))} characters")
    return np.array(images), np.array(labels)

def create_simple_model():
    """Create a simpler CNN model for faster training"""
    model = keras.Sequential([
        # Input layer
        layers.Input(shape=(INPUT_SIZE, INPUT_SIZE, 1)),
        
        # Convolutional layers
        layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
        layers.MaxPooling2D((2, 2)),
        
        layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        layers.MaxPooling2D((2, 2)),
        
        layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        layers.MaxPooling2D((2, 2)),
        
        # Dense layers
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.5),
        layers.Dense(256, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(NUM_CLASSES, activation='softmax')
    ])
    
    return model

def main():
    print("Quick Japanese Character Recognition Training")
    print("=" * 50)
    
    # Load dataset
    data_dir = "dataset"
    if not os.path.exists(data_dir):
        print(f"Error: Dataset directory '{data_dir}' not found!")
        return
    
    X, y = load_dataset(data_dir)
    
    if len(X) == 0:
        print("Error: No images found in dataset!")
        return
    
    # Split dataset
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"Training set: {len(X_train)} images")
    print(f"Test set: {len(X_test)} images")
    
    # Create model
    model = create_simple_model()
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("Model architecture:")
    model.summary()
    
    # Train model
    print("Training model...")
    history = model.fit(
        X_train, y_train,
        batch_size=BATCH_SIZE,
        epochs=EPOCHS,
        validation_data=(X_test, y_test),
        verbose=1
    )
    
    # Evaluate model
    print("Evaluating model...")
    test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"Test accuracy: {test_accuracy:.4f}")
    
    # Convert to TFLite
    print("Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    # Save the model
    with open('japanese_character_model.tflite', 'wb') as f:
        f.write(tflite_model)
    
    print("Model saved as 'japanese_character_model.tflite'")
    
    # Save labels
    with open('japanese_character_labels.txt', 'w', encoding='utf-8') as f:
        for label in CHARACTER_LABELS:
            f.write(f"{label}\n")
    
    print("Labels saved as 'japanese_character_labels.txt'")
    
    # Get model size
    model_size = len(tflite_model) / (1024 * 1024)  # MB
    print(f"Model size: {model_size:.2f} MB")
    
    # Plot training history
    plt.figure(figsize=(12, 4))
    
    plt.subplot(1, 2, 1)
    plt.plot(history.history['accuracy'], label='Training Accuracy')
    plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
    plt.title('Model Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.legend()
    
    plt.subplot(1, 2, 2)
    plt.plot(history.history['loss'], label='Training Loss')
    plt.plot(history.history['val_loss'], label='Validation Loss')
    plt.title('Model Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('training_history.png')
    print("Training history saved as 'training_history.png'")
    
    print("\nTraining completed successfully!")
    print("Next steps:")
    print("1. Copy 'japanese_character_model.tflite' to 'assets/models/' in your Flutter project")
    print("2. Copy 'japanese_character_labels.txt' to 'assets/models/' in your Flutter project")
    print("3. Update pubspec.yaml to include the assets")
    print("4. Run your Flutter app to test the real model!")

if __name__ == "__main__":
    main()
