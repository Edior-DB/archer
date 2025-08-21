
// Redmondi (Windows-like) KDE Plasma 6 layout script
// Single bottom panel: Kickoff, Icon Tasks, System Tray, Digital Clock (Windows 10/11 style)

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

    // --- Bottom Panel (Taskbar) ---
    var panel = new Panel;
    panel.location = "bottom";
    panel.height = 44; // Modern Windows-like height
    panel.floating = true; // Windows 11 style
    panel.immutability = 1;

    // Left: Application Launcher (Kickoff)
    panel.addWidget("org.kde.plasma.kickoff");

    // Center: Icon Tasks (modern Windows look)
    panel.addWidget("org.kde.plasma.icontasks");

    // Right: System Tray, Digital Clock
    panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
}

main();
