
// Cupertini (macOS-like) KDE Plasma 6 layout script
// Top panel: launcher, global menu, system tray, clock (macOS style)
// Bottom panel: dock-style, centered icons

function main() {
    // Remove all panels and reset desktops
    var allContainments = desktops().concat(panels());
    for (var i = 0; i < allContainments.length; ++i) {
        allContainments[i].remove();
    }

    // Desktop containment (plain desktop, no icons)
    var desktop = desktops()[0];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.immutability = 1;

    // --- Top Panel (Menu Bar) ---
    var topPanel = new Panel;
    topPanel.location = "top";
    topPanel.height = 36; // macOS-like height
    topPanel.immutability = 1;


    // Left: Application Launcher (Kickoff or similar), then Global Menu (macOS style)
    topPanel.addWidget("org.kde.plasma.kickoff");
    topPanel.addWidget("org.kde.plasma.globalmenu");

    // Right: System Tray, Digital Clock
    topPanel.addWidget("org.kde.plasma.systemtray");
    topPanel.addWidget("org.kde.plasma.digitalclock");

    // --- Bottom Panel (Dock) ---
    var dock = new Panel;
    dock.location = "bottom";
    dock.height = 56; // macOS-like dock height
    dock.floating = true;
    dock.alignment = "center";
    dock.immutability = 1;
    var iconTasks = dock.addWidget("org.kde.plasma.icontasks");
    // let's add some often-used applications to the dock such as browser, terminal, etc.
    iconTasks.widget.addApplication("org.kde.firefox.desktop");
    iconTasks.widget.addApplication("org.kde.konsole.desktop");

    // Optionally, adjust iconTasks.widget properties for spacing/appearance

    // --- Manual Steps ---
    // - For a macOS-like control center, add a suitable plasmoid to the top panel's right (if/when available for Plasma 6)
    // - Customize panel backgrounds and blur in KDE settings for a more authentic look
    // - Add any additional widgets as desired
}

main();
