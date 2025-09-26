#!/bin/bash
# TypeScript Programming Language Installation
# Typed superset of JavaScript for better development experience

set -e

# Source common functions
source "${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/system/common-funcs.sh"

show_banner "TypeScript Programming Language"

echo -e "${BLUE}TypeScript - Typed superset of JavaScript${NC}"
echo -e "${YELLOW}Installing TypeScript via npm (requires Node.js)${NC}"
echo ""

# (Confirmation helper moved to install/system/common-funcs.sh)

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js not found. TypeScript requires Node.js to be installed.${NC}"
    echo -e "${BLUE}Please install Node.js first using the nodejs installer.${NC}"

    # if confirm_action "Install Node.js first?"; then
        # Run nodejs installer if available
        nodejs_installer="${ARCHER_DIR:-$(dirname "${BASH_SOURCE[0]}")/../..}/install/development/scripting-web/nodejs.sh"
        if [[ -f "$nodejs_installer" ]]; then
            bash "$nodejs_installer"
        else
            echo -e "${YELLOW}Node.js installer not found. Installing via Mise...${NC}"
            if command -v mise &> /dev/null; then
                mise install node@latest
                mise use -g node@latest
                eval "$(mise activate bash)" 2>/dev/null || true
            else
                echo -e "${RED}Please install Node.js manually first.${NC}"
                exit 1
            fi
        fi
    # else
        # echo -e "${YELLOW}TypeScript installation cancelled.${NC}"
        # exit 0
    # fi
fi

# Verify Node.js and npm are available
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm not found. Please ensure Node.js is properly installed.${NC}"
    exit 1
fi

# if ! confirm_action "Install TypeScript globally via npm?"; then
#     echo -e "${YELLOW}TypeScript installation cancelled.${NC}"
#     exit 0
# fi

echo -e "${BLUE}Installing TypeScript globally...${NC}"

# Install TypeScript globally
if npm install -g typescript; then
    echo -e "${GREEN}✓ TypeScript installed successfully!${NC}"

    # Install additional helpful TypeScript tools
    echo -e "${BLUE}Installing additional TypeScript development tools...${NC}"

    # ts-node for running TypeScript directly
    if npm install -g ts-node; then
        echo -e "${GREEN}✓ ts-node installed successfully!${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to install ts-node${NC}"
    fi

    # TypeScript ESLint support
    if npm install -g @typescript-eslint/parser @typescript-eslint/eslint-plugin; then
        echo -e "${GREEN}✓ TypeScript ESLint support installed!${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to install TypeScript ESLint support${NC}"
    fi

    # Show version and information
    typescript_version=$(tsc --version 2>/dev/null || echo "Not available")
    node_version=$(node --version 2>/dev/null || echo "Not available")
    npm_version=$(npm --version 2>/dev/null || echo "Not available")
    tsnode_status="Available"
    if ! command -v ts-node &>/dev/null; then
        tsnode_status="Not installed"
    fi

    echo -e "${GREEN}
=========================================================================
                      TypeScript Installation Complete!
=========================================================================

Installed versions:
  $typescript_version
  Node.js: $node_version
  npm: $npm_version
  ts-node: $tsnode_status

Key commands:
  tsc file.ts               # Compile TypeScript to JavaScript
  tsc --init                # Create tsconfig.json
  tsc --watch               # Watch mode compilation
  ts-node file.ts           # Run TypeScript directly (if installed)
  npm run build             # Project build (if configured)
  npm run dev               # Development server (if configured)

TypeScript Compiler (tsc):
  tsc --init                # Initialize tsconfig.json
  tsc                       # Compile all files
  tsc app.ts                # Compile specific file
  tsc --watch               # Watch for changes
  tsc --target ES2020       # Specify target
  tsc --module commonjs     # Specify module system
  tsc --strict              # Enable strict mode

Project setup:
  mkdir my-ts-project
  cd my-ts-project
  npm init -y               # Initialize package.json
  tsc --init                # Initialize tsconfig.json
  npm install -D @types/node # Node.js type definitions

Common TypeScript files:
  tsconfig.json             # TypeScript configuration
  .ts                       # TypeScript source files
  .d.ts                     # Type definition files
  package.json              # npm configuration

Hello World example:
  echo 'console.log(\"Hello, TypeScript World!\");' > hello.ts
  tsc hello.ts              # Compiles to hello.js
  node hello.js             # Run compiled JavaScript

Or with ts-node:
  ts-node hello.ts          # Run directly

Basic TypeScript example:
  cat > example.ts << 'EOF'
interface Person {
  name: string;
  age: number;
}

function greet(person: Person): string {
  return \`Hello, \${person.name}! You are \${person.age} years old.\`;
}

const user: Person = {
  name: \"Alice\",
  age: 30
};

console.log(greet(user));
EOF

  tsc example.ts && node example.js

tsconfig.json example:
  {
    \"compilerOptions\": {
      \"target\": \"ES2020\",
      \"module\": \"commonjs\",
      \"outDir\": \"./dist\",
      \"strict\": true,
      \"esModuleInterop\": true,
      \"skipLibCheck\": true
    },
    \"include\": [\"src/**/*\"],
    \"exclude\": [\"node_modules\", \"dist\"]
  }

npm scripts (package.json):
  {
    \"scripts\": {
      \"build\": \"tsc\",
      \"start\": \"node dist/index.js\",
      \"dev\": \"ts-node src/index.ts\",
      \"watch\": \"tsc --watch\"
    }
  }

Popular TypeScript frameworks:
  - Express.js with types: npm install express @types/express
  - React with TypeScript: npx create-react-app my-app --template typescript
  - Vue with TypeScript: vue create my-app (select TypeScript)
  - Angular (built-in TypeScript support)
  - Next.js with TypeScript: npx create-next-app@latest --typescript

Type definitions:
  npm install -D @types/node        # Node.js types
  npm install -D @types/express     # Express types
  npm install -D @types/lodash      # Lodash types
  npm search @types/package-name    # Search for types

Development tools:
  - VS Code: Excellent TypeScript support
  - ESLint: npm install -D @typescript-eslint/parser
  - Prettier: npm install -D prettier
  - Jest: npm install -D jest @types/jest ts-jest

TypeScript features:
  - Static type checking
  - Modern JavaScript features
  - Excellent IDE support
  - Gradual adoption
  - Large ecosystem
  - Compile-time error detection

Documentation: https://www.typescriptlang.org/
Handbook: https://www.typescriptlang.org/docs/
Playground: https://www.typescriptlang.org/play/
${NC}"

    # Suggest creating a sample project
    echo ""
  if archer_confirm_or_default "Create a sample TypeScript project?" "no"; then
        project_dir="$HOME/typescript-sample"
        echo -e "${BLUE}Creating sample project in $project_dir...${NC}"

        mkdir -p "$project_dir"
        cd "$project_dir"

        # Initialize npm project
        npm init -y > /dev/null

        # Initialize TypeScript config
        tsc --init > /dev/null

        # Create source directory
        mkdir -p src

        # Create sample TypeScript file
        cat > src/index.ts << 'EOF'
interface User {
  id: number;
  name: string;
  email: string;
}

class UserManager {
  private users: User[] = [];

  addUser(user: User): void {
    this.users.push(user);
    console.log(`Added user: ${user.name}`);
  }

  getUserById(id: number): User | undefined {
    return this.users.find(user => user.id === id);
  }

  listUsers(): void {
    console.log('Users:');
    this.users.forEach(user => {
      console.log(`  ${user.id}: ${user.name} (${user.email})`);
    });
  }
}

// Usage
const userManager = new UserManager();

userManager.addUser({
  id: 1,
  name: "Alice Johnson",
  email: "alice@example.com"
});

userManager.addUser({
  id: 2,
  name: "Bob Smith",
  email: "bob@example.com"
});

userManager.listUsers();

const user = userManager.getUserById(1);
if (user) {
  console.log(`Found user: ${user.name}`);
}
EOF

        # Update package.json with scripts
        cat > package.json << 'EOF'
{
  "name": "typescript-sample",
  "version": "1.0.0",
  "description": "Sample TypeScript project",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "watch": "tsc --watch"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  },
  "keywords": ["typescript", "sample"],
  "author": "",
  "license": "ISC"
}
EOF

        # Install dev dependencies
        npm install > /dev/null 2>&1 || true

        echo -e "${GREEN}✓ Sample TypeScript project created in $project_dir${NC}"
        echo -e "${YELLOW}Commands to try:${NC}"
        echo -e "  cd $project_dir"
        echo -e "  npm run build     # Compile TypeScript"
        echo -e "  npm start         # Run compiled JavaScript"
        echo -e "  npm run dev       # Run with ts-node"
        echo -e "  npm run watch     # Watch mode compilation"
    fi

else
    echo -e "${RED}✗ Failed to install TypeScript${NC}"
    echo -e "${YELLOW}You can try manual installation:${NC}"
    echo -e "  npm install -g typescript"
    echo -e "  npm install -g ts-node"
    exit 1
fi

wait_for_input
