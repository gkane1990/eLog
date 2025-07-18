📘 eLog - Event Logger for WoW (v1.2)

A clean, modular, and efficient World of Warcraft AddOn for real-time event tracking with session-based storage and a live UI. Built using the powerful Ace3 framework.
🚀 Features

    Session-Based Logging: Automatically starts a new log session every time you log in.

    Real-time Event Tracking: Captures system messages and combat log events like UNIT_DIED.

    Customizable UI: A clean, movable, and resizable frame to view logs.

    Efficient Display: Uses a frame pool to recycle UI elements, ensuring smooth performance even with many log entries.

    Configurable: Use the in-game options panel to toggle timestamps, lock the frame, and set the maximum number of logs to keep.

    Data Management: Easily clear all logs or export your entire log history to the chat frame.

    Lightweight & Modular: Built with Ace3 for a robust and maintainable codebase.

🧩 Modules

The addon is broken down into the following logical components:

    eLog.lua: The core addon file. Handles initialization, event registration, and module loading.

    eLog_Options.lua: Defines the configuration panel seen in the Interface Options.

    eLog_Sessions.lua: Manages the creation, storage, and cleanup of log sessions.

    eLog_UI.lua: Creates and manages all user interface elements.

    eLog_Utils.lua: Contains helper functions for tasks like timestamp formatting and data exporting.

    Locales\\: Contains localization files for different languages.

🛠️ Installation

    Download the latest release.

    Extract the eLog folder into your World of Warcraft\\_classic_\\Interface\\AddOns\\ directory.

    Restart the WoW client or type /reload in the chat.

🔧 Slash Commands

    /elog - Opens the main configuration panel.

    /elog ui - Toggles the visibility of the log window.

    /elog clear - Deletes all stored log sessions.

    /elog help - Shows a list of available commands.

🙌 Acknowledgements

    The authors and contributors of the Ace3 Library.

    The amazing WoW addon community at WoWInterface.

    Made with ❤️ for WoW addon developers by Garbis Ciftci