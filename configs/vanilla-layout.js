// Vanilla KDE Plasma layout script generated from default-plasma-org.kde.plasma.desktop-appletsrc
// This script can be loaded with qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.loadLayout <path>

// WARNING: This is a direct translation of the appletsrc config. You may want to further customize or clean up for scripting.

function main() {
    // Remove all existing panels and desktops
    var allContainments = desktops().concat(panels());
    for (var i = 0; i < allContainments.length; ++i) {
        allContainments[i].remove();
    }

    // Desktop containment
    var desktop = new Containment("org.kde.plasma.folder");
    desktop.location = 0;
    desktop.immutability = 1;
    desktop.wallpaperPlugin = "org.kde.image";

    // Panel containment
    var panel = new Panel;
    panel.location = 4;
    panel.immutability = 1;
    panel.wallpaperPlugin = "org.kde.image";

    // Add widgets to panel (order based on AppletOrder)
    panel.addWidget("org.kde.plasma.kickoff");
    panel.addWidget("org.kde.plasma.pager");
    panel.addWidget("org.kde.plasma.icontasks");
    panel.addWidget("org.kde.plasma.marginsseparator");
    var systray = panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
    panel.addWidget("org.kde.plasma.showdesktop");

    // Optionally, configure systray sub-applets (not all can be set via script)
    // Optionally, set panel size, icon size, etc. (not all can be set via script)
}

main();
