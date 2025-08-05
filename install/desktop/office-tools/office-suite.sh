#!/bin/bash

# Office Suite Selection Script for Arch Linux
# Part of Archer - Arch Linux Home PC Transformation Suite

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Confirm function using gum
confirm_action() {
    local message="$1"
    gum confirm "$message"
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --value "" > /dev/null
}

# Input function using gum
get_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    gum input --prompt "$prompt " --placeholder "$placeholder"
}

# Show logo
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
 ██████╗ ███████╗███████╗██╗ ██████╗███████╗    ████████╗ ██████╗  ██████╗ ██╗     ███████╗
██╔═══██╗██╔════╝██╔════╝██║██╔════╝██╔════╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
██║   ██║█████╗  █████╗  ██║██║     █████╗         ██║   ██║   ██║██║   ██║██║     ███████╗
██║   ██║██╔══╝  ██╔══╝  ██║██║     ██╔══╝         ██║   ██║   ██║██║   ██║██║     ╚════██║
╚██████╔╝██║     ██║     ██║╚██████╗███████╗       ██║   ╚██████╔╝╚██████╔╝███████╗███████║
 ╚═════╝ ╚═╝     ╚═╝     ╚═╝ ╚═════╝╚══════╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝

                            Office Suite Selection
EOF
    echo -e "${NC}"
}

# Check for AUR helper
check_aur_helper() {
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        echo -e "${RED}AUR helper not found. Please run post-install.sh first.${NC}"
        exit 1
    fi

    # Set AUR helper
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        AUR_HELPER="yay"
    fi
}

# Install LibreOffice
install_libreoffice() {
    echo -e "${BLUE}Installing LibreOffice...${NC}"

    local packages=(
        "libreoffice-fresh"
        "libreoffice-fresh-en-us"
        "hunspell"
        "hunspell-en_us"
        "hyphen"
        "hyphen-en"
        "libmythes"
        "mythes-en"
    )

    echo -e "${YELLOW}Installing LibreOffice packages...${NC}"
    for package in "${packages[@]}"; do
        sudo pacman -S --noconfirm --needed "$package" || echo -e "${YELLOW}Could not install $package${NC}"
    done

    # Optional language packs
    read -p "Install additional language packs? (y/N): " install_langs
    if [[ "$install_langs" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Available languages:${NC}"
        echo "1) Spanish (es)"
        echo "2) French (fr)"
        echo "3) German (de)"
        echo "4) Italian (it)"
        echo "5) Portuguese (pt-br)"
        echo "6) Russian (ru)"
        echo "7) Chinese Simplified (zh-cn)"
        echo "8) Japanese (ja)"

        read -p "Enter language numbers (space-separated, e.g., 1 3 5): " lang_choices

        declare -A lang_codes=(
            [1]="es"
            [2]="fr"
            [3]="de"
            [4]="it"
            [5]="pt-br"
            [6]="ru"
            [7]="zh-cn"
            [8]="ja"
        )

        for choice in $lang_choices; do
            if [[ -n "${lang_codes[$choice]}" ]]; then
                local lang="${lang_codes[$choice]}"
                echo -e "${YELLOW}Installing language pack for $lang...${NC}"
                sudo pacman -S --noconfirm --needed "libreoffice-fresh-$lang" || true
                sudo pacman -S --noconfirm --needed "hunspell-$lang" || true
                sudo pacman -S --noconfirm --needed "hyphen-$lang" || true
            fi
        done
    fi

    echo -e "${GREEN}LibreOffice installed successfully!${NC}"
}

# Install OnlyOffice
install_onlyoffice() {
    echo -e "${BLUE}Installing OnlyOffice...${NC}"

    echo -e "${YELLOW}Installing OnlyOffice Desktop Editors...${NC}"
    $AUR_HELPER -S --noconfirm onlyoffice-bin

    echo -e "${GREEN}OnlyOffice installed successfully!${NC}"
}

# Install WPS Office
install_wps() {
    echo -e "${BLUE}Installing WPS Office...${NC}"

    echo -e "${YELLOW}Installing WPS Office from AUR...${NC}"
    $AUR_HELPER -S --noconfirm wps-office

    # Install fonts for better compatibility
    echo -e "${YELLOW}Installing WPS Office fonts...${NC}"
    $AUR_HELPER -S --noconfirm ttf-wps-fonts || echo -e "${YELLOW}Could not install WPS fonts${NC}"

    echo -e "${GREEN}WPS Office installed successfully!${NC}"
}

# Install FreeOffice
install_freeoffice() {
    echo -e "${BLUE}Installing FreeOffice...${NC}"

    echo -e "${YELLOW}Installing SoftMaker FreeOffice...${NC}"
    $AUR_HELPER -S --noconfirm freeoffice

    echo -e "${GREEN}FreeOffice installed successfully!${NC}"
}

# Install Calligra Suite
install_calligra() {
    echo -e "${BLUE}Installing Calligra Suite...${NC}"

    local packages=(
        "calligra"
        "calligra-extras"
    )

    echo -e "${YELLOW}Installing Calligra packages...${NC}"
    for package in "${packages[@]}"; do
        sudo pacman -S --noconfirm --needed "$package"
    done

    echo -e "${GREEN}Calligra Suite installed successfully!${NC}"
}

# Install Office 365 (Web)
install_office365() {
    echo -e "${BLUE}Setting up Office 365 Web Access...${NC}"

    # Create desktop shortcuts for Office 365 web apps
    local desktop_dir="$HOME/Desktop"
    local apps_dir="$HOME/.local/share/applications"

    mkdir -p "$desktop_dir" "$apps_dir"

    # Office 365 Portal
    cat > "$apps_dir/office365-portal.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Office 365
Comment=Microsoft Office 365 Web Portal
Exec=firefox https://office.com
Icon=applications-office
Terminal=false
Categories=Office;
EOF

    # Word Online
    cat > "$apps_dir/word-online.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Word Online
Comment=Microsoft Word Online
Exec=firefox https://office.com/launch/word
Icon=application-msword
Terminal=false
Categories=Office;WordProcessor;
EOF

    # Excel Online
    cat > "$apps_dir/excel-online.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Excel Online
Comment=Microsoft Excel Online
Exec=firefox https://office.com/launch/excel
Icon=application-vnd.ms-excel
Terminal=false
Categories=Office;Spreadsheet;
EOF

    # PowerPoint Online
    cat > "$apps_dir/powerpoint-online.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=PowerPoint Online
Comment=Microsoft PowerPoint Online
Exec=firefox https://office.com/launch/powerpoint
Icon=application-vnd.ms-powerpoint
Terminal=false
Categories=Office;Presentation;
EOF

    # Make desktop entries executable
    chmod +x "$apps_dir"/*.desktop

    # Copy to desktop if it exists
    if [[ -d "$desktop_dir" ]]; then
        cp "$apps_dir"/office365-portal.desktop "$desktop_dir/"
        cp "$apps_dir"/word-online.desktop "$desktop_dir/"
        cp "$apps_dir"/excel-online.desktop "$desktop_dir/"
        cp "$apps_dir"/powerpoint-online.desktop "$desktop_dir/"
        chmod +x "$desktop_dir"/*.desktop
    fi

    echo -e "${GREEN}Office 365 web shortcuts created!${NC}"
    echo -e "${CYAN}You can now access Office 365 applications from your application menu.${NC}"
}

# Install Google Workspace shortcuts
install_google_workspace() {
    echo -e "${BLUE}Setting up Google Workspace shortcuts...${NC}"

    local apps_dir="$HOME/.local/share/applications"
    local desktop_dir="$HOME/Desktop"

    mkdir -p "$apps_dir" "$desktop_dir"

    # Google Docs
    cat > "$apps_dir/google-docs.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Docs
Comment=Google Docs - Online Document Editor
Exec=firefox https://docs.google.com
Icon=text-editor
Terminal=false
Categories=Office;WordProcessor;
EOF

    # Google Sheets
    cat > "$apps_dir/google-sheets.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Sheets
Comment=Google Sheets - Online Spreadsheet Editor
Exec=firefox https://sheets.google.com
Icon=application-vnd.ms-excel
Terminal=false
Categories=Office;Spreadsheet;
EOF

    # Google Slides
    cat > "$apps_dir/google-slides.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Slides
Comment=Google Slides - Online Presentation Editor
Exec=firefox https://slides.google.com
Icon=application-vnd.ms-powerpoint
Terminal=false
Categories=Office;Presentation;
EOF

    # Google Drive
    cat > "$apps_dir/google-drive.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Drive
Comment=Google Drive - Cloud Storage
Exec=firefox https://drive.google.com
Icon=folder-cloud
Terminal=false
Categories=Office;FileManager;
EOF

    # Make desktop entries executable
    chmod +x "$apps_dir"/*.desktop

    # Copy to desktop if it exists
    if [[ -d "$desktop_dir" ]]; then
        cp "$apps_dir"/google-*.desktop "$desktop_dir/"
        chmod +x "$desktop_dir"/google-*.desktop
    fi

    echo -e "${GREEN}Google Workspace shortcuts created!${NC}"
}

# Show office suite comparison
show_comparison() {
    echo -e "${CYAN}
===============================================
              Office Suite Comparison
===============================================${NC}"

    echo -e "${GREEN}LibreOffice${NC} - Free & Open Source"
    echo -e "  ${YELLOW}✓${NC} Full-featured office suite"
    echo -e "  ${YELLOW}✓${NC} Best MS Office compatibility"
    echo -e "  ${YELLOW}✓${NC} Supports many file formats"
    echo -e "  ${YELLOW}✓${NC} Completely free"
    echo -e "  ${YELLOW}✓${NC} Available in many languages"
    echo ""

    echo -e "${GREEN}OnlyOffice${NC} - MS Office Compatible"
    echo -e "  ${YELLOW}✓${NC} Excellent MS Office compatibility"
    echo -e "  ${YELLOW}✓${NC} Modern interface"
    echo -e "  ${YELLOW}✓${NC} Real-time collaboration"
    echo -e "  ${YELLOW}✓${NC} Free desktop version"
    echo ""

    echo -e "${GREEN}WPS Office${NC} - MS Office-like Interface"
    echo -e "  ${YELLOW}✓${NC} Interface very similar to MS Office"
    echo -e "  ${YELLOW}✓${NC} Good compatibility"
    echo -e "  ${YELLOW}✓${NC} Fast and lightweight"
    echo -e "  ${YELLOW}⚠${NC}  Free with ads (premium available)"
    echo ""

    echo -e "${GREEN}FreeOffice${NC} - SoftMaker Office"
    echo -e "  ${YELLOW}✓${NC} High MS Office compatibility"
    echo -e "  ${YELLOW}✓${NC} Professional layout"
    echo -e "  ${YELLOW}✓${NC} Free version available"
    echo -e "  ${YELLOW}⚠${NC}  Limited features in free version"
    echo ""

    echo -e "${GREEN}Calligra Suite${NC} - KDE Office Suite"
    echo -e "  ${YELLOW}✓${NC} Integrates well with KDE"
    echo -e "  ${YELLOW}✓${NC} Unique workflow approach"
    echo -e "  ${YELLOW}✓${NC} Good for creative projects"
    echo -e "  ${YELLOW}⚠${NC}  Less MS Office compatibility"
    echo ""

    echo -e "${GREEN}Office 365 Web${NC} - Microsoft Online"
    echo -e "  ${YELLOW}✓${NC} Official Microsoft Office"
    echo -e "  ${YELLOW}✓${NC} Always up-to-date"
    echo -e "  ${YELLOW}✓${NC} Cloud storage included"
    echo -e "  ${YELLOW}⚠${NC}  Requires internet connection"
    echo -e "  ${YELLOW}⚠${NC}  Subscription required for full features"
    echo ""

    echo -e "${GREEN}Google Workspace${NC} - Google Office Suite"
    echo -e "  ${YELLOW}✓${NC} Excellent collaboration features"
    echo -e "  ${YELLOW}✓${NC} Automatic cloud saving"
    echo -e "  ${YELLOW}✓${NC} Free with Google account"
    echo -e "  ${YELLOW}⚠${NC}  Requires internet connection"
    echo -e "  ${YELLOW}⚠${NC}  Limited offline capabilities"
    echo ""

    echo -e "${CYAN}===============================================${NC}"
}

# Show menu
show_menu() {
    clear
    show_logo
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}           Choose Your Office Suite           ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}Desktop Office Suites:${NC}"
    echo "  1) LibreOffice (Recommended - Full-featured & Free)"
    echo "  2) OnlyOffice (MS Office Compatible)"
    echo "  3) WPS Office (MS Office-like Interface)"
    echo "  4) FreeOffice (SoftMaker Office)"
    echo "  5) Calligra Suite (KDE Native)"
    echo ""
    echo -e "${GREEN}Web-based Office:${NC}"
    echo "  6) Office 365 Web Access (Microsoft)"
    echo "  7) Google Workspace (Google Docs/Sheets/Slides)"
    echo ""
    echo -e "${CYAN}Other Options:${NC}"
    echo "  8) Install Multiple Suites"
    echo "  9) Show Detailed Comparison"
    echo ""
    echo " 0) Back to Main Menu"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
}

# Install multiple suites
install_multiple() {
    echo -e "${BLUE}Multiple Office Suites Installation${NC}"
    echo ""
    echo "Select suites to install (space-separated numbers):"
    echo "1) LibreOffice  2) OnlyOffice  3) WPS Office"
    echo "4) FreeOffice   5) Calligra    6) Office 365 Web"
    echo "7) Google Workspace"
    echo ""
    read -p "Enter your choices: " choices

    for choice in $choices; do
        case $choice in
            1) install_libreoffice ;;
            2) install_onlyoffice ;;
            3) install_wps ;;
            4) install_freeoffice ;;
            5) install_calligra ;;
            6) install_office365 ;;
            7) install_google_workspace ;;
            *) echo -e "${YELLOW}Invalid choice: $choice${NC}" ;;
        esac
    done
}

# Main function
main() {
    check_aur_helper

    while true; do
        show_menu
        read -p "Select an option [0-9]: " choice

        case $choice in
            1)
                install_libreoffice
                read -p "Press Enter to continue..."
                ;;
            2)
                install_onlyoffice
                read -p "Press Enter to continue..."
                ;;
            3)
                install_wps
                read -p "Press Enter to continue..."
                ;;
            4)
                install_freeoffice
                read -p "Press Enter to continue..."
                ;;
            5)
                install_calligra
                read -p "Press Enter to continue..."
                ;;
            6)
                install_office365
                read -p "Press Enter to continue..."
                ;;
            7)
                install_google_workspace
                read -p "Press Enter to continue..."
                ;;
            8)
                install_multiple
                read -p "Press Enter to continue..."
                ;;
            9)
                show_comparison
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}Returning to main menu...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main
