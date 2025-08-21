// Redmondi (Windows-like) KDE Plasma layout script
// Loads a bottom panel with a task manager and launcher, similar to Windows

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

    // Panel containment (bottom)
    var panel = new Panel;
    panel.location = 4;
    panel.immutability = 1;
    panel.wallpaperPlugin = "org.kde.image";

    // Add widgets to panel (Windows-like order)
    panel.addWidget("org.kde.plasma.kickoff");
    panel.addWidget("org.kde.plasma.taskmanager");
    panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
}

main();
