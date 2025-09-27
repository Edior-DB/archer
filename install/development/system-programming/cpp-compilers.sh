#!/bin/bash
# C/C++ Compilers Installation
# GCC and Clang/LLVM toolchains for systems programming

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "C/C++ Compilers Installation"

echo -e "${BLUE}C/C++ Development Environment${NC}"
echo -e "${YELLOW}Installing both GCC and Clang/LLVM toolchains${NC}"
echo -e "${YELLOW}Components:${NC}"
echo -e "  • GCC (GNU Compiler Collection)"
echo -e "  • Clang/LLVM (Modern C/C++ compiler)"
echo -e "  • Build tools: Make, CMake, Ninja"
echo -e "  • Development libraries"
echo ""

if ! archer_confirm_or_default "Install C/C++ compilers and build tools?"; then
  echo -e "${YELLOW}C/C++ toolchain installation cancelled.${NC}"
  return 0
fi

echo -e "${BLUE}Installing C/C++ development environment...${NC}"

# C/C++ with both GCC and Clang (LLVM)
packages=(
    "gcc" "glibc" "make" "cmake" "ninja"
    "clang" "llvm" "lld"
    "gdb" "valgrind"
)

if install_with_retries "${packages[@]}"; then
    echo -e "${GREEN}✓ C/C++ compilers installed successfully!${NC}"

    # Show installed versions
    gcc_version=$(gcc --version | head -1 2>/dev/null || echo "Not available")
    clang_version=$(clang --version | head -1 2>/dev/null || echo "Not available")
    cmake_version=$(cmake --version | head -1 2>/dev/null || echo "Not available")

    echo -e "${GREEN}
=========================================================================
                    C/C++ Development Environment Complete!
=========================================================================

Installed versions:
  GCC: $gcc_version
  Clang: $clang_version
  CMake: $cmake_version

Available compilers:
  gcc / g++                 # GNU Compiler Collection
  clang / clang++          # LLVM C/C++ compiler

Build tools:
  make                     # Traditional build tool
  cmake                    # Modern build system generator
  ninja                    # Fast build tool

Debug tools:
  gdb                      # GNU Debugger
  valgrind                 # Memory debugging tool

Basic usage:
  gcc hello.c -o hello     # Compile C with GCC
  g++ hello.cpp -o hello   # Compile C++ with GCC
  clang hello.c -o hello   # Compile C with Clang
  clang++ hello.cpp -o hello # Compile C++ with Clang

CMake project workflow:
  mkdir build && cd build
  cmake ..
  make

Next steps:
- Try creating a simple Hello World program
- Explore CMake for project management
- Use gdb for debugging: 'gdb ./your_program'
- Use valgrind for memory checking: 'valgrind ./your_program'

Documentation:
  GCC: https://gcc.gnu.org/
  Clang: https://clang.llvm.org/
  CMake: https://cmake.org/
${NC}"

else
  echo -e "${RED}✗ Failed to install C/C++ compilers${NC}"
  archer_die "Failed to install C/C++ compilers"
fi

wait_for_input
