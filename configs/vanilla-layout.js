// Vanilla KDE Plasma layout script generated from default-plasma-org.kde.plasma.desktop-appletsrc
// This script can be loaded with qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.loadLayout <path>

// WARNING: This is a direct translation of the appletsrc config. You may want to further customize or clean up for scripting.


function main() {
    // Remove all existing panels and desktops
    var allContainments = desktops().concat(panels());
    for (var i = 0; i < allContainments.length; ++i) {
        allContainments[i].remove();
    }

    // Desktop containment (folder view, with icons)
    var desktop = desktops()[0];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.immutability = 1;
    desktop.plugin = "org.kde.plasma.folder";

    // Panel containment (bottom)
    var panel = new Panel;
    panel.location = "bottom";
    panel.immutability = 1;
    panel.addWidget("org.kde.plasma.kickoff");
    panel.addWidget("org.kde.plasma.pager");
    panel.addWidget("org.kde.plasma.icontasks");
    panel.addWidget("org.kde.plasma.marginsseparator");
    var systray = panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
    panel.addWidget("org.kde.plasma.showdesktop");
}

main();
