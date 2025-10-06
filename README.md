# 🚀 Flutter Learning Sandbox

## A Personal Laboratory for Dart & Flutter Development

This repository serves as my dedicated space for hands-on practice, experimentation, and mastery of the **Flutter framework** and the **Dart language**. The primary goal is to build a strong foundation in mobile development, explore advanced widget techniques, and prepare for future freelance projects.

---

## 🎯 Project Goals

This sandbox is focused on achieving the following learning objectives:

* **Core Fundamentals:** Solidifying understanding of **Stateful** vs. **Stateless** widgets, **Widget Trees**, and the fundamental **Build Context**.
* **State Management:** Implementing and comparing various state management solutions (e.g., Provider, Riverpod, Bloc) within small, focused features.
* **UI/UX Mastery:** Creating responsive layouts using `Row`, `Column`, `Flex`, and `CustomPainter` for different screen sizes.
* **External Integration:** Practicing **API calls** (REST/GraphQL), data parsing, and local data persistence (e.g., using `shared_preferences` or databases).
* **Code Quality:** Focusing on clean architecture, Dart language idioms, and writing effective unit and widget tests.

---

## 🧩 Features Implemented So Far

As part of my learning journey, I’ve already built:

- ⏱ **Pomodoro Timer** – A customizable timer with adjustable settings for focused work and short breaks.  
- 💬 **Motivational Quotes Page** – Uses the free [ZenQuotes API](https://zenquotes.io) with `FutureBuilder` to fetch and display inspirational quotes, complete with pull-to-refresh and error handling.

---

## 🛠️ Tech Stack & Prerequisites

### Technologies Used
| Component | Purpose |
| :--- | :--- |
| **Flutter** | Cross-platform UI toolkit |
| **Dart** | Programming language |
| **Android SDK** | Building and running Android versions |
| **VS Code** | Primary development IDE |

### Getting Started

To clone and run this project locally, ensure you have the following installed:

1.  **Flutter SDK:** (Confirmed working via `flutter doctor`)
2.  **Android/iOS Setup:** Required build tools for your target platform.
3.  **IDE:** VS Code or Android Studio with the Flutter/Dart extensions.

### Installation & Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YourUsername/flutter-learning-sandbox.git
    cd flutter-learning-sandbox
    ```
2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Launch an Emulator/Device:** Start your Android Emulator or connect a physical device.
4.  **Run the application:**
    ```bash
    flutter run
    ```
    *(Alternatively, use the 'Run and Debug' button in your IDE.)*

---

## 📂 Repository Structure

The code is organized primarily in the `lib` directory, with features often separated into dedicated folders.

| Directory | Content |
| :--- | :--- |
| `lib/` | Primary Dart source code. |
| `lib/features/` | Modular, self-contained demos (e.g., state management, custom animations). **(To be added)** |
| `lib/core/` | Global themes, constants, and utilities. |
| `assets/` | Fonts, images, and other resources. |
| `test/` | Unit tests and widget tests. |

---

## 🤝 Contribution

This is a personal learning repository, but suggestions, feedback, and links to useful resources are always welcome! Feel free to open an issue if you spot a major mistake or inefficiency in the code.
