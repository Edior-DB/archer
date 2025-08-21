// Cupertini (macOS-like) KDE Plasma layout script
// Loads a top panel and a dock, similar to macOS

function main() {
    // Remove all existing panels and desktops
    var allContainments = desktops().concat(panels());
    for (var i = 0; i < allContainments.length; ++i) {
        allContainments[i].remove();
    }

    // Desktop containment
    var desktop = new Containment("org.kde.plasma.desktop");
    desktop.location = 0;
    desktop.immutability = 1;
    desktop.wallpaperPlugin = "org.kde.image";

    // Top panel (menu bar)
    var topPanel = new Panel;
    topPanel.location = 0;
    topPanel.immutability = 1;
    topPanel.wallpaperPlugin = "org.kde.image";
    topPanel.addWidget("org.kde.plasma.kickoff");
    topPanel.addWidget("org.kde.plasma.systemtray");
    topPanel.addWidget("org.kde.plasma.digitalclock");

    // Bottom panel (dock)
    var dock = new Panel;
    dock.location = 3;
    dock.immutability = 1;
    dock.wallpaperPlugin = "org.kde.image";
    var tasks = dock.addWidget("org.kde.plasma.icontasks");
    // Optionally, set favorite launchers (not all versions support this in script)
}

main();
