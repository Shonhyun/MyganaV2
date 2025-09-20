#!/usr/bin/env python3
"""
Japanese Character Recognition Model Training Script

This script trains a TensorFlow Lite model for recognizing Japanese characters (Hiragana and Katakana).
The trained model can be integrated into the Flutter app for real-time character recognition.

Requirements:
- tensorflow
- numpy
- matplotlib
- scikit-learn

Usage:
1. Prepare your dataset in the following structure:
   dataset/
   ├── hiragana/
   │   ├── あ/
   │   │   ├── image1.png
   │   │   ├── image2.png
   │   │   └── ...
   │   ├── い/
   │   └── ...
   └── katakana/
       ├── ア/
       ├── イ/
       └── ...

2. Run the training script:
   python train_japanese_model.py

3. The trained model will be saved as 'japanese_character_model.tflite'
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import json

# Model configuration
INPUT_SIZE = 64
NUM_CLASSES = 92  # 46 Hiragana + 46 Katakana = 92 total characters
BATCH_SIZE = 32
EPOCHS = 50
LEARNING_RATE = 0.001

# Character labels (Hiragana + Katakana)
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

def create_model():
    """Create the CNN model architecture"""
    model = keras.Sequential([
        # Input layer
        layers.Input(shape=(INPUT_SIZE, INPUT_SIZE, 1)),
        
        # Convolutional layers
        layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        
        layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        
        layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        
        layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        
        # Dense layers
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.5),
        layers.Dense(512, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(256, activation='relu'),
        layers.Dropout(0.2),
        layers.Dense(NUM_CLASSES, activation='softmax')
    ])
    
    return model

def train_model():
    """Train the model"""
    # Load dataset
    data_dir = "dataset"  # Change this to your dataset path
    if not os.path.exists(data_dir):
        print(f"Error: Dataset directory '{data_dir}' not found!")
        print("Please create the dataset directory and organize your images as described in the script header.")
        return None
    
    X, y = load_dataset(data_dir)
    
    if len(X) == 0:
        print("Error: No images found in dataset!")
        return None
    
    # Split dataset
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"Training set: {len(X_train)} images")
    print(f"Test set: {len(X_test)} images")
    
    # Create model
    model = create_model()
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Print model summary
    model.summary()
    
    # Data augmentation
    datagen = keras.preprocessing.image.ImageDataGenerator(
        rotation_range=10,
        width_shift_range=0.1,
        height_shift_range=0.1,
        shear_range=0.1,
        zoom_range=0.1,
        horizontal_flip=False,  # Don't flip Japanese characters
        fill_mode='nearest'
    )
    
    # Train model
    print("Training model...")
    history = model.fit(
        datagen.flow(X_train, y_train, batch_size=BATCH_SIZE),
        steps_per_epoch=len(X_train) // BATCH_SIZE,
        epochs=EPOCHS,
        validation_data=(X_test, y_test),
        verbose=1
    )
    
    # Evaluate model
    print("Evaluating model...")
    test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"Test accuracy: {test_accuracy:.4f}")
    
    # Generate predictions for detailed evaluation
    y_pred = model.predict(X_test)
    y_pred_classes = np.argmax(y_pred, axis=1)
    
    # Print classification report
    print("\nClassification Report:")
    # Get unique labels from the actual dataset
    unique_labels = sorted(list(set(y_test)))
    actual_labels = [CHARACTER_LABELS[i] for i in unique_labels if i < len(CHARACTER_LABELS)]
    print(classification_report(y_test, y_pred_classes, labels=unique_labels, target_names=actual_labels))
    
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
    plt.show()
    
    return model

def convert_to_tflite(model):
    """Convert the trained model to TensorFlow Lite format"""
    print("Converting model to TensorFlow Lite...")
    
    # Convert to TFLite
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

def create_sample_dataset():
    """Create a sample dataset for testing (if no real dataset is available)"""
    print("Creating sample dataset for testing...")
    
    os.makedirs("dataset", exist_ok=True)
    
    for char in CHARACTER_LABELS[:10]:  # Create samples for first 10 characters
        char_dir = os.path.join("dataset", char)
        os.makedirs(char_dir, exist_ok=True)
        
        # Create 10 sample images for each character
        for i in range(10):
            # Generate a simple pattern (in real scenario, you'd have actual character images)
            img = np.random.rand(INPUT_SIZE, INPUT_SIZE) * 255
            img = img.astype(np.uint8)
            
            # Save as PNG
            from PIL import Image
            pil_img = Image.fromarray(img, mode='L')
            pil_img.save(os.path.join(char_dir, f"sample_{i}.png"))
    
    print("Sample dataset created. Replace with real character images for better results.")

if __name__ == "__main__":
    print("Japanese Character Recognition Model Training")
    print("=" * 50)
    
    # Check if dataset exists
    if not os.path.exists("dataset"):
        print("No dataset found. Creating sample dataset...")
        create_sample_dataset()
        print("\nPlease replace the sample images with real Japanese character images.")
        print("Organize them in folders named after each character.")
        print("Then run this script again to train the model.")
    else:
        # Train the model
        model = train_model()
        
        if model is not None:
            # Convert to TFLite
            convert_to_tflite(model)
            
            print("\nTraining completed successfully!")
            print("Next steps:")
            print("1. Copy 'japanese_character_model.tflite' to 'assets/models/' in your Flutter project")
            print("2. Copy 'japanese_character_labels.txt' to 'assets/models/' in your Flutter project")
            print("3. Update pubspec.yaml to include the assets")
            print("4. Run your Flutter app to test the real model!")
        else:
            print("Training failed. Please check your dataset and try again.")
