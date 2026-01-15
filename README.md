# Ruby LSP Plugin for Claude Code

Dead-simple Ruby LSP integration for Claude Code with intelligent guidance on LSP usage.

## What This Does

Connects Claude Code to the Ruby LSP server, providing semantic code intelligence through the LSP tool:
- Go-to-definition (with inheritance & mixins support)
- Find references across project
- Hover documentation with signatures
- Document and workspace symbol navigation
- Call hierarchy analysis (incoming/outgoing calls)
- Implementation finding

**Plus:** Automatic SessionStart hook that guides Claude on when and how to use the 9 LSP operations proactively, ensuring optimal use of semantic analysis over text-based searches.

## Prerequisites

```bash
gem install ruby-lsp
```

## Installation

```bash
/plugin marketplace add benjaminjackson/ruby-lsp
/plugin install ruby-lsp@ruby-lsp-marketplace
```

## How It Works

### LSP Server Integration

The plugin automatically starts the Ruby LSP server when Claude Code launches in a Ruby project. The LSP tool is a first-class tool (like Read, Bash, Edit) that requires three parameters:
- **filePath**: Absolute path to the Ruby file
- **line**: Line number (1-indexed)
- **character**: Character position (1-indexed)

### SessionStart Hook

On session start, Claude receives comprehensive guidance on:
- **9 available LSP operations** - goToDefinition, hover, findReferences, documentSymbol, workspaceSymbol, goToImplementation, prepareCallHierarchy, incomingCalls, outgoingCalls
- **When to use LSP** - For definitions, references, hover docs, call analysis, symbol search
- **When NOT to use LSP** - Clear guidance on when standard tools (Read, Grep) are better
- **Best practices** - Optimal workflows combining LSP and standard tools

This ensures Claude uses semantic analysis when appropriate (finding definitions, understanding call chains) rather than text-based searches (Grep for "def method_name").

## Available LSP Operations

The LSP tool provides 9 operations for Ruby code intelligence:

### 1. goToDefinition
**Find where a symbol is defined**
- Supports: Classes, modules, methods (including inherited), singleton methods, instance variables, local variables, super keyword
- Use case: Navigate to exact definition location
- Why: Understands Ruby scope, inheritance, and mixins

### 2. hover
**Get hover information (documentation, type info)**
- Supports: Methods, constants, instance variables (including inherited), Ruby core classes/methods
- Use case: View method signatures, parameter info, documentation
- Why: Provides formatted docs with parameter info

### 3. findReferences
**Find all references to a symbol**
- Returns: All locations where symbol is referenced across project
- Use case: See where methods/classes are used
- Why: Understands Ruby semantics, not just text matches

### 4. documentSymbol
**Get all symbols in a document**
- Returns: Hierarchical symbol tree of classes, modules, methods in file
- Use case: Understand file structure quickly
- Why: Provides structured view instantly

### 5. workspaceSymbol
**Search for symbols across workspace**
- Returns: Matching symbols from entire workspace
- Use case: Find classes, modules, methods across project
- Why: LSP indexes workspace and understands Ruby structure

### 6. goToImplementation
**Find implementations of an interface or abstract method**
- Returns: File paths and positions of implementations
- Use case: Working with abstract methods, find concrete implementations
- Why: Semantic understanding of Ruby class hierarchies

### 7. prepareCallHierarchy
**Get call hierarchy item at a position**
- Returns: Call hierarchy item for the function
- Use case: Understand call structure of methods
- Why: Provides context for method call chains

### 8. incomingCalls
**Find all functions/methods that call the function at a position**
- Returns: List of callers for the method
- Use case: See what calls this method ("who calls me?")
- Why: Understand method usage and dependencies

### 9. outgoingCalls
**Find all functions/methods called by the function at a position**
- Returns: List of methods called by this method
- Use case: See what this method calls ("what do I call?")
- Why: Understand method dependencies and flow

## Example Usage

**Finding a method definition:**
```
User: Where is the process_payment method defined?
Claude: [Uses LSP operation="goToDefinition" instead of Grep]
        [Supports inherited methods from superclasses and mixins]
```

**Understanding method signature:**
```
User: What parameters does process_payment accept?
Claude: [Uses LSP operation="hover" to get signature and docs]
```

**Finding all uses of a method:**
```
User: Where is process_payment called?
Claude: [Uses LSP operation="findReferences" across entire project]
        [Not just text matches - understands Ruby semantics]
```

**Exploring unfamiliar codebase:**
```
User: Show me all payment-related classes
Claude: [Uses LSP operation="workspaceSymbol" to search across project]
        [Uses operation="goToDefinition" to navigate to each]
        [Uses operation="documentSymbol" to see file structure]
```

**Analyzing call chains:**
```
User: What calls the validate_payment method?
Claude: [Uses LSP operation="incomingCalls" to find all callers]

User: What does validate_payment call?
Claude: [Uses LSP operation="outgoingCalls" to see dependencies]
```

**Refactoring safely:**
```
User: I want to refactor this method
Claude: [Uses LSP operation="findReferences" to find all usages first]
        [Uses operation="incomingCalls" to see all callers]
        [Makes changes with Edit]
        [Uses operation="findReferences" again to verify]
```

## Key Advantages

- **Semantic understanding** - LSP understands Ruby scope, inheritance, and mixins, not just text patterns
- **Proactive guidance** - Claude knows when to use LSP vs standard tools automatically
- **Call analysis** - Understand method dependencies with incomingCalls/outgoingCalls
- **Project-wide search** - Find references and symbols across entire workspace
- **First-class tool** - LSP is a built-in tool like Read, Bash, and Edit
