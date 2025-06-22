# Supra Code Generator MCP
Lean MCP integration for generating Supra Move contracts and TypeScript SDK code.

<div align="center">

[![Follow on Twitter](https://img.shields.io/twitter/follow/SupraOracles?style=social)](https://twitter.com/SUPRA_Labs)
[![Join Discord](https://img.shields.io/discord/850682587273625661?style=social&logo=discord)](https://discord.com/invite/supralabs)

</div>

### **One-Click Installation**

```bash
curl -fsSL https://raw.githubusercontent.com/JatinSupra/Supra-mcp-code-gen/refs/heads/main/supra/move_workspace/MCP_SUPRA/script/set.sh | bash
chmod +x set.sh && ./set.sh
```

## Features

- **Move Contract Generation**: Production-ready contracts with security patterns
- **TypeScript SDK Generation**: Complete client code with examples
- **NFT Marketplace Patterns**: Based on production-ready templates

## Usage in Claude

### Quick Demo

```bash
You: "Create an NFT marketplace with auction features"
```
OR

```bash
You: "Create TypeScript SDK code for an NFT marketplace."
```
> Allow Claude to use the supra-code-MCP from the pop-up.

## Manual Setup

**If auto-config failed, add to Claude Desktop config:**

```json
{
  "mcpServers": {
    "supra-code-MCP": {
      "command": "node",
      "args": ["/PATH TO/supra-code-gen/build/index.js"]
    }
  }
}
```

> Restart Claude Desktop after configuration.

## **Example Prompts**

```
"Build a prediction market for sports events with supra oracle price feeds"
```

```
"Create a decentralized lending platform with collateral management"
```

```
"Build a virtual real estate marketplace"
```