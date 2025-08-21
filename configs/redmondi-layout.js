// Redmondi (Windows-like) KDE Plasma layout script
// Loads a bottom panel with a task manager and launcher, similar to Windows


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

    // Panel containment (bottom)
    var panel = new Panel;
    panel.location = "bottom";
    panel.immutability = 1;
    panel.addWidget("org.kde.plasma.kickoff");
    panel.addWidget("org.kde.plasma.taskmanager");
    panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
}

main();
