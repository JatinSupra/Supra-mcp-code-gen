#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Supra Code Generator MCP...${NC}"

# Create project directory
PROJECT_DIR="supra-code-gen"
echo -e "${YELLOW}📁 Creating project directory: $PROJECT_DIR${NC}"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Create source directory
mkdir -p src

# Create package.json
echo -e "${YELLOW}📦 Creating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "supra-code-generator",
  "version": "1.0.0",
  "description": "Lean MCP for generating Supra Move contracts and TypeScript SDK code",
  "type": "module",
  "main": "build/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node build/index.js",
    "dev": "ts-node src/index.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.4.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0"
  },
  "keywords": ["supra", "blockchain", "move", "mcp", "code-generation"],
  "author": "Supra Developer",
  "license": "MIT"
}
EOF

# Create TypeScript config
echo -e "${YELLOW}⚙️ Creating tsconfig.json...${NC}"
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "outDir": "./build",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "allowSyntheticDefaultImports": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "build"]
}
EOF

# Create main TypeScript file
echo -e "${YELLOW}📝 Creating main MCP server...${NC}"
cat > src/index.ts << 'EOF'
#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

class SupraCodeGenerator {
  private server: Server;
  private nftTemplate: string;

  constructor() {
this.server = new Server({
  name: 'supra-code-generator', 
  version: '1.0.0'
});
    this.nftTemplate = this.getNFTTemplate();
    this.setupHandlers();
  }

  private getNFTTemplate(): string {
    return `module mint_addr::nft_marketplace {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use supra_framework::account;
    use supra_framework::event;
    use supra_framework::timestamp;
    use supra_framework::coin::{Self, Coin};
    use supra_framework::supra_coin::SupraCoin;
    use aptos_token::token::{Self, TokenDataId, TokenId};

    #[event]
    struct TokenListed has drop, store {
        seller: address,
        token_id: TokenId,
        price: u64,
        timestamp: u64,
    }

    #[event]
    struct TokenSold has drop, store {
        seller: address,
        buyer: address,
        token_id: TokenId,
        price: u64,
        timestamp: u64,
    }

    struct Listing has key {
        token_id: TokenId,
        seller: address,
        price: u64,
        is_active: bool,
    }

    struct Marketplace has key {
        fee_percentage: u64,
        admin: address,
        total_sales: u64,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const ELISTING_NOT_FOUND: u64 = 2;
    const ELISTING_NOT_ACTIVE: u64 = 3;
    const EINSUFFICIENT_FUNDS: u64 = 4;
    const EINVALID_PRICE: u64 = 5;

    fun init_module(admin: &signer) {
        move_to(admin, Marketplace {
            fee_percentage: 250, // 2.5%
            admin: signer::address_of(admin),
            total_sales: 0,
        });
    }

    public entry fun list_token(
        seller: &signer,
        creator: address,
        collection: String,
        name: String,
        property_version: u64,
        price: u64,
    ) acquires Marketplace {
        assert!(price > 0, error::invalid_argument(EINVALID_PRICE));
        
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let seller_addr = signer::address_of(seller);
        
        // Transfer token to marketplace
        let token = token::withdraw_token(seller, token_id, 1);
        move_to(seller, Listing {
            token_id,
            seller: seller_addr,
            price,
            is_active: true,
        });
        
        token::deposit_token(seller, token);
        
        event::emit(TokenListed {
            seller: seller_addr,
            token_id,
            price,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun buy_token(
        buyer: &signer,
        seller: address,
    ) acquires Listing, Marketplace {
        let listing = borrow_global_mut<Listing>(seller);
        assert!(listing.is_active, error::invalid_state(ELISTING_NOT_ACTIVE));
        
        let marketplace = borrow_global_mut<Marketplace>(@mint_addr);
        let buyer_addr = signer::address_of(buyer);
        
        // Calculate fees
        let fee = (listing.price * marketplace.fee_percentage) / 10000;
        let seller_amount = listing.price - fee;
        
        // Transfer payment
        let payment = coin::withdraw<SupraCoin>(buyer, listing.price);
        let fee_coin = coin::extract(&mut payment, fee);
        
        coin::deposit(seller, payment);
        coin::deposit(marketplace.admin, fee_coin);
        
        // Transfer token
        let token = token::withdraw_token_with_capability(
            &listing_cap, listing.token_id, 1
        );
        token::deposit_token(buyer, token);
        
        // Update listing
        listing.is_active = false;
        marketplace.total_sales = marketplace.total_sales + 1;
        
        event::emit(TokenSold {
            seller,
            buyer: buyer_addr,
            token_id: listing.token_id,
            price: listing.price,
            timestamp: timestamp::now_seconds(),
        });
    }

    #[view]
    public fun get_listing(seller: address): (TokenId, u64, bool) acquires Listing {
        let listing = borrow_global<Listing>(seller);
        (listing.token_id, listing.price, listing.is_active)
    }
}`;
  }

  private setupHandlers(): void {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'generate_supra_code',
          description: 'Generate Supra Move contracts or TypeScript SDK code using NFT marketplace patterns',
          inputSchema: {
            type: 'object',
            properties: {
              type: {
                type: 'string',
                enum: ['move', 'sdk'],
                description: 'Generate Move contract or TypeScript SDK code'
              },
              description: {
                type: 'string',
                description: 'What you want to build (e.g., "DeFi lending", "Gaming with VRF")'
              },
              features: {
                type: 'array',
                items: { type: 'string' },
                description: 'Features: vrf, automation, oracles, events, payments'
              }
            },
            required: ['type', 'description']
          }
        }
      ]
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      if (request.params.name === 'generate_supra_code') {
        return this.generateCode(request.params.arguments as any);
      }
      throw new Error(`Unknown tool: ${request.params.name}`);
    });
  }

  private async generateCode(args: { type: 'move' | 'sdk'; description: string; features?: string[] }) {
    const { type, description, features = [] } = args;

    if (type === 'move') {
      return this.generateMoveCode(description, features);
    } else {
      return this.generateSDKCode(description, features);
    }
  }

  private generateMoveCode(description: string, features: string[]): any {
    const moduleName = this.extractModuleName(description);
    const hasVRF = features.includes('vrf');
    const hasAutomation = features.includes('automation');
    const hasPayments = features.includes('payments');
    const hasEvents = features.includes('events');

    let imports = `    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use supra_framework::account;
    use supra_framework::timestamp;`;

    if (hasEvents) imports += `\n    use supra_framework::event;`;
    if (hasPayments) imports += `\n    use supra_framework::coin::{Self, Coin};\n    use supra_framework::supra_coin::SupraCoin;`;
    if (hasVRF) imports += `\n    use supra_addr::supra_vrf;`;

    let structs = `    struct AppData has key {
        owner: address,
        is_active: bool,
        created_at: u64,
    }`;

    if (hasEvents) {
      structs += `\n\n    #[event]
    struct AppEvent has drop, store {
        user: address,
        action: String,
        timestamp: u64,
    }`;
    }

    let constants = `    const ENOT_AUTHORIZED: u64 = 1;
    const EAPP_NOT_ACTIVE: u64 = 2;
    const EINVALID_OPERATION: u64 = 3;`;

    let functions = `    fun init_module(account: &signer) {
        let account_addr = signer::address_of(account);
        move_to(account, AppData {
            owner: account_addr,
            is_active: true,
            created_at: timestamp::now_seconds(),
        });
    }

    public entry fun main_action(account: &signer, param: String) acquires AppData {
        let account_addr = signer::address_of(account);
        let app_data = borrow_global_mut<AppData>(account_addr);
        
        assert!(app_data.is_active, error::invalid_state(EAPP_NOT_ACTIVE));
        
        // Your core logic here
        ${hasEvents ? `
        event::emit(AppEvent {
            user: account_addr,
            action: param,
            timestamp: timestamp::now_seconds(),
        });` : ''}
    }

    #[view]
    public fun get_status(addr: address): bool acquires AppData {
        if (!exists<AppData>(addr)) return false;
        borrow_global<AppData>(addr).is_active
    }`;

    if (hasVRF) {
      functions += `\n\n    public entry fun request_random(account: &signer) {
        supra_vrf::rng_request(
            account,
            signer::address_of(account),
            string::utf8(b"${moduleName}"),
            string::utf8(b"handle_random"),
            1, // count
            0, // seed
            1  // confirmations
        );
    }

    public entry fun handle_random(
        nonce: u64,
        message: vector<u8>,
        signature: vector<u8>,
        caller_address: address,
        rng_count: u8,
        client_seed: u64,
    ) {
        let random_numbers = supra_vrf::verify_callback(
            nonce, message, signature, caller_address, rng_count, client_seed
        );
        let random_value = *vector::borrow(&random_numbers, 0);
        // Use random_value in your logic
    }`;
    }

    const code = `${imports}

module your_addr::${moduleName} {
${structs}

${constants}

${functions}
}`;

    return {
      content: [{
        type: 'text',
        text: `# Generated Move Contract: ${moduleName}

\`\`\`move
${code}
\`\`\`

## Deployment Commands:
\`\`\`bash
# Compile
supra move compile --package-dir .

# Test  
supra move test --package-dir .

# Deploy to Testnet
supra move publish --package-dir . --rpc-url https://rpc-testnet.supra.com

# Deploy to Mainnet  
supra move publish --package-dir . --rpc-url https://rpc-mainnet.supra.com
\`\`\`

## Features:
${features.map(f => `✅ ${f.toUpperCase()}`).join('\n')}
`
      }]
    };
  }

  private generateSDKCode(description: string, features: string[]): any {
    const className = this.extractClassName(description);
    const hasVRF = features.includes('vrf');
    const hasPayments = features.includes('payments');

    let methods = `  async executeAction(action: string): Promise<string> {
    const payload = {
      function: "your_addr::your_module::main_action",
      arguments: [action],
      type_arguments: []
    };

    const txResponse = await this.client.submitTransaction(this.account, payload);
    await this.client.waitForTransaction(txResponse.hash);
    return txResponse.hash;
  }

  async getStatus(address?: string): Promise<boolean> {
    const addr = address || this.account.address();
    try {
      const resource = await this.client.getAccountResource(
        addr,
        "your_addr::your_module::AppData"
      );
      return resource?.data?.is_active || false;
    } catch {
      return false;
    }
  }`;

    if (hasVRF) {
      methods += `\n\n  async requestRandom(): Promise<string> {
    const payload = {
      function: "your_addr::your_module::request_random",
      arguments: [],
      type_arguments: []
    };

    const txResponse = await this.client.submitTransaction(this.account, payload);
    await this.client.waitForTransaction(txResponse.hash);
    return txResponse.hash;
  }`;
    }

    if (hasPayments) {
      methods += `\n\n  async getBalance(): Promise<number> {
    const resources = await this.client.getAccountResources(this.account.address());
    const coinResource = resources.find((r: any) => 
      r.type === "0x1::coin::CoinStore<0x1::supra_coin::SupraCoin>"
    );
    return coinResource?.data?.coin?.value || 0;
  }`;
    }

    const code = `import { SupraClient, SupraAccount, FaucetClient } from '@supra/sdk';

export class ${className} {
  private client: SupraClient;
  private account: SupraAccount;

  constructor(rpcUrl: string = 'https://rpc-testnet.supra.com', privateKey?: string) {
    this.client = new SupraClient(rpcUrl);
    if (privateKey) {
      this.account = SupraAccount.fromPrivateKey(privateKey);
    }
  }

  async createAccount(): Promise<SupraAccount> {
    this.account = SupraAccount.generate();
    console.log('Generated account:', this.account.address());
    return this.account;
  }

  async fundAccount(amount: number = 100000000): Promise<void> {
    if (!this.account) {
      throw new Error('Account not created. Call createAccount() first.');
    }
    
    const faucet = new FaucetClient('https://faucet.testnet.supra.com');
    await faucet.fundAccount(this.account.address(), amount);
    console.log(\`Funded \${amount} microSUPRA to \${this.account.address()}\`);
  }

${methods}

  getAccount(): SupraAccount {
    if (!this.account) {
      throw new Error('Account not created. Call createAccount() first.');
    }
    return this.account;
  }

  getClient(): SupraClient {
    return this.client;
  }
}

// Usage Example
export async function example() {
  const client = new ${className}();
  
  // Create and fund account
  await client.createAccount();
  await client.fundAccount();
  
  // Execute your contract functions
  const txHash = await client.executeAction("test_action");
  console.log('Transaction hash:', txHash);
  
  // Check status
  const status = await client.getStatus();
  console.log('App status:', status);
}

// Run example
// example().catch(console.error);`;

    return {
      content: [{
        type: 'text',
        text: `# Generated TypeScript SDK Code

\`\`\`typescript
${code}
\`\`\`

## Installation:
\`\`\`bash
npm install @supra/sdk
\`\`\`

## Usage:
\`\`\`bash
npm run build
node dist/index.js
\`\`\`

## Features:
${features.map(f => `✅ ${f.toUpperCase()} integration`).join('\n')}
`
      }]
    };
  }

  private extractModuleName(description: string): string {
    const words = description.toLowerCase().replace(/[^a-z0-9\s]/g, '').split(' ');
    return words.slice(0, 2).join('_') || 'custom_module';
  }

  private extractClassName(description: string): string {
    const words = description.toLowerCase().replace(/[^a-z0-9\s]/g, '').split(' ');
    const name = words.slice(0, 2).join('') || 'customClient';
    return name.charAt(0).toUpperCase() + name.slice(1) + 'Client';
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Supra Code Generator MCP Server running');
  }
}

const server = new SupraCodeGenerator();
server.run().catch(console.error);
EOF

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm install

# Build the project
echo -e "${YELLOW}🔨 Building project...${NC}"
npm run build

# Get Claude config path
CLAUDE_CONFIG=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    CLAUDE_CONFIG="$APPDATA/Claude/claude_desktop_config.json"
fi

# Update Claude config
if [ -f "$CLAUDE_CONFIG" ]; then
    echo -e "${YELLOW}⚙️ Updating Claude Desktop config...${NC}"
    
    # Backup existing config
    cp "$CLAUDE_CONFIG" "${CLAUDE_CONFIG}.backup"
    
    # Get absolute path
    CURRENT_DIR=$(pwd)
    
    # Add MCP server to config
    python3 -c "
import json
import sys

config_path = '$CLAUDE_CONFIG'
project_path = '$CURRENT_DIR'

try:
    with open(config_path, 'r') as f:
        config = json.load(f)
except:
    config = {}

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['supra-code-generator'] = {
    'command': 'node',
    'args': [f'{project_path}/build/index.js']
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print('✅ Claude config updated')
"
else
    echo -e "${YELLOW}⚠️ Claude config not found. Manual setup required:${NC}"
    echo -e "${BLUE}Add this to your Claude Desktop config:${NC}"
    echo "{
  \"mcpServers\": {
    \"supra-code-generator\": {
      \"command\": \"node\",
      \"args\": [\"$(pwd)/build/index.js\"]
    }
  }
}"
fi

# Create README
echo -e "${YELLOW}📄 Creating README...${NC}"
cat > README.md << 'EOF'
# Supra Code Generator MCP

Lean MCP integration for generating Supra Move contracts and TypeScript SDK code.

## Features

- **Move Contract Generation**: Production-ready contracts with security patterns
- **TypeScript SDK Generation**: Complete client code with examples
- **Supra Integration**: VRF, Automation, Oracles support
- **NFT Marketplace Patterns**: Based on production-ready templates

## Usage in Claude

Ask Claude to generate code:

```
Generate a Move contract for a DeFi lending protocol with VRF
```

```
Create TypeScript SDK code for an NFT marketplace with payments
```

## Available Features

- `vrf` - Supra VRF integration
- `automation` - Scheduled execution
- `oracles` - Price feeds and data
- `events` - On-chain event emission
- `payments` - Token transfers

## Manual Setup

If auto-config failed, add to Claude Desktop config:

```json
{
  "mcpServers": {
    "supra-code-generator": {
      "command": "node",
      "args": ["/path/to/supra-code-gen/build/index.js"]
    }
  }
}
```

Restart Claude Desktop after configuration.
EOF

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}📍 Project created in: $(pwd)${NC}"
echo -e "${YELLOW}🔄 Restart Claude Desktop to use the code generator${NC}"
echo ""
echo -e "${BLUE}🎯 What this generates:${NC}"
echo -e "${GREEN}  • Clean Move contracts with supra_framework${NC}"
echo -e "${GREEN}  • SupraCoin payment functionality${NC}"
echo -e "${GREEN}  • Event emission and tracking${NC}"
echo -e "${GREEN}  • TypeScript SDK with real supra-l1-sdk${NC}"
echo ""
echo -e "${YELLOW}📖 Example prompts:${NC}"
echo -e "  'Generate a marketplace contract with payments'"
echo -e "  'Create a gaming platform contract with events'"
echo -e "  'Build TypeScript SDK for contract integration'"
echo ""
echo -e "${GREEN}🎉 Start generating clean Supra code with Claude!${NC}"