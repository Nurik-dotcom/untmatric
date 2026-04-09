# UNTformatic

UNTformatic is a puzzle/hacking game built with Godot 4.5. It focuses on logic, decryption, signal processing, and system stability, challenging players to solve complex computational problems under pressure.

## Features

*   **Logic Gates:** Analyze input/output behavior to identify logic gates (AND, OR, NOT, XOR, NAND, NOR).
*   **Decryption:** Perform bitwise operations (AND, OR, XOR, SHIFT) across different number systems (Binary, Decimal, Octal, Hexadecimal).
*   **Radio Intercept:** Tune signals and process waveforms to intercept communications.
*   **Suspect Analysis:** Trace code execution and analyze logic flow to uncover hidden values.
*   **Code Restoration:** Reconstruct broken code blocks using drag-and-drop mechanics.
*   **Disarm Protocol:** Debug and fix code errors to stabilize systems.
*   **City Map:** Optimize paths and navigate graph-based networks.
*   **Data Archive:** Query and filter data using SQL-like logic.
*   **Network Trace:** Track packets through complex network topologies.

## Core Mechanics

*   **Stability:** Each level starts with 100% stability. Errors decrease stability, and critical failures trigger a "Safe Mode".
*   **Hamming Distance:** Solution verification often uses Hamming distance to provide feedback on how close an answer is to the target.
*   **Shields:**
    *   **Frequency Shield:** Prevents rapid-fire guessing.
    *   **Lazy Shield:** Penalizes small, incremental changes without significant logic shifts.
*   **Responsive UI:** Designed to adapt to both mobile and desktop layouts with a Noir/Cyberpunk aesthetic.

## Tech Stack

*   **Engine:** Godot 4.5 (Mobile renderer feature set).
*   **Language:** GDScript.
*   **Data:** JSON-based level configuration (located in `data/`).

## Project Structure

*   `scenes/`: UI layouts and game scenes for each quest type.
*   `scripts/`: Core logic for quests, global metrics, and UI handling.
*   `data/`: JSON files defining levels and puzzles (e.g., `quest_b_levels.json`, `quest_c_levels.json`).
*   `ui/`: Theme resources, shaders (CRT, Blur), and reusable UI components.

## How to Run

1.  Download or clone the repository.
2.  Open the project in Godot Engine 4.5 or later.
3.  Run the project (F5) to start from the main menu (`scenes/MainMenu.tscn`).

## License

MIT License. See [LICENSE](LICENSE) for details.
