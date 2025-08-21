// Cupertini (macOS-like) KDE Plasma layout script
// Loads a top panel and a dock, similar to macOS


function main() {
    // Remove all existing panels and desktops
    var allContainments = desktops().concat(panels());
    for (var i = 0; i < allContainments.length; ++i) {
        allContainments[i].remove();
    }

    // Desktop containment (plain desktop, no icons)
    var desktop = desktops()[0];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.immutability = 1;

    // Top panel (menu bar)
    var topPanel = new Panel;
    topPanel.location = "top";
    topPanel.immutability = 1;
    topPanel.addWidget("org.kde.plasma.kickoff");
    topPanel.addWidget("org.kde.plasma.systemtray");
    topPanel.addWidget("org.kde.plasma.digitalclock");

    // Bottom panel (dock)
    var dock = new Panel;
    dock.location = "bottom";
    dock.immutability = 1;
    dock.addWidget("org.kde.plasma.icontasks");
}

main();
