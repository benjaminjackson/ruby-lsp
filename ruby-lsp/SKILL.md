---
name: ruby-lsp
description: This skill should be loaded when working with Ruby files to understand when to use LSP operations (documentSymbol, findReferences, goToDefinition, hover, workspaceSymbol, incomingCalls, outgoingCalls) versus standard tools (Read, Grep). Critical for preventing unnecessary file reads when structural information is needed.
---

# Ruby LSP Usage Guidance

This project has Ruby LSP (shopify/ruby-lsp) integration enabled. Use the LSP tool proactively for Ruby code intelligence.

## CRITICAL: Check This Decision Tree FIRST

**BEFORE Reading Any Ruby File**, determine what information is needed:

**Need to know what methods exist?** → **documentSymbol** ✅
**Need to understand class/module structure?** → **documentSymbol** ✅
**Need method signatures or parameters?** → **documentSymbol** ✅
**Need to see instance variables?** → **documentSymbol** ✅
**Need file overview or high-level structure?** → **documentSymbol** ✅
**Need to find where a method is defined?** → **goToDefinition** ✅
**Need to see where a method is called?** → **findReferences** ✅

**Only use Read when:**
- Need specific implementation details in method bodies
- Need to see actual code logic
- Need comments, strings, or non-structural content

**Key Rule:** NEVER use Read to get structural information. ALWAYS use LSP operations first.

**The documentSymbol operation provides:**
- All classes and modules
- All methods with line numbers
- All instance variables
- Hierarchical structure
- Instant response without loading large files

**Example Flow:**

❌ **Wrong:**
```
Task: Understand what methods are available in generate_briefs.rb
Assistant: [Reads entire 1183-line file to find method definitions]
```

✅ **Correct:**
```
Task: Understand what methods are available in generate_briefs.rb
Assistant: [Uses LSP documentSymbol operation]
Assistant: [Gets structured list of 58 symbols instantly]
```

## The LSP Tool

The LSP tool is a first-class tool (like Read, Bash, Edit) that provides semantic code intelligence for Ruby files. All operations require three parameters:
- **filePath**: Absolute path to the Ruby file
- **line**: Line number (1-indexed, as shown in editors)
- **character**: Character position (1-indexed, as shown in editors)

## Available LSP Operations (9 Total)

### 1. goToDefinition
**Find where a symbol is defined**
- Use when: Need to find where classes, modules, methods, variables are defined
- Supports: Classes, modules, methods (including inherited), singleton methods, instance variables, local variables, super keyword
- Why use: Understands Ruby scope, inheritance, and mixins - provides exact locations even for inherited methods
- ❌ Don't use Grep to search for "def method_name" or "class ClassName"

### 2. hover
**Get hover information (documentation, type info)**
- Use when: Need to view method signatures, parameter info, documentation, source code preview
- Supports: Methods, constants, instance variables (including inherited), Ruby core classes/methods
- Why use: Provides formatted docs with parameter info, works with Ruby core methods
- ❌ Don't use Read + manual parsing to find method definition

### 3. documentSymbol
**Get all symbols in a document**
- Use when: Need to understand file structure (classes, modules, methods)
- Returns: Hierarchical symbol tree of all classes, modules, methods in file
- Why use: Provides structured, hierarchical view instantly
- ❌ Don't use Read + manual parsing for classes/methods

### 4. workspaceSymbol
**Search for symbols across workspace**
- Use when: Need to find classes, modules, methods across entire project
- Returns: Matching symbols from entire workspace
- Why use: LSP indexes the entire workspace and understands Ruby structure
- ❌ Don't use Glob + Grep for class/method definitions

### 5. findReferences
**Find all references to a symbol**
- Use when: Need to see where methods/classes are used across the project
- Returns: All locations where symbol is referenced
- Why use: Understands Ruby semantics, not just text matches
- ❌ Don't use Grep to search for method name strings

### 6. goToImplementation
**Find implementations of an interface or abstract method**
- Use when: Working with abstract methods or interfaces, need to find concrete implementations
- Returns: File paths and positions of implementations
- Why use: Semantic understanding of Ruby class hierarchies

### 7. prepareCallHierarchy
**Get call hierarchy item at a position**
- Use when: Need to understand the call structure of functions/methods
- Returns: Call hierarchy item for the function at position
- Why use: Provides context for method call chains

### 8. incomingCalls
**Find all functions/methods that call the function at a position**
- Use when: Need to see what calls this method ("who calls me?")
- Returns: List of callers for the method
- Why use: Understand method usage and dependencies

### 9. outgoingCalls
**Find all functions/methods called by the function at a position**
- Use when: Need to see what this method calls ("what do I call?")
- Returns: List of methods called by this method
- Why use: Understand method dependencies and flow

## When to Use LSP (ALWAYS PREFER LSP)

**Use LSP operations proactively when:**

1. **Finding method/class definitions** → Use `goToDefinition`
2. **Understanding method signatures and parameters** → Use `hover`
3. **Understanding file structure** → Use `documentSymbol`
4. **Searching for symbols across entire project** → Use `workspaceSymbol`
5. **Finding where a method/class is used** → Use `findReferences`
6. **Finding implementations** → Use `goToImplementation`
7. **Understanding who calls a method** → Use `incomingCalls`
8. **Understanding what a method calls** → Use `outgoingCalls`
9. **Analyzing call chains** → Use `prepareCallHierarchy`

## When NOT to Use LSP (Use Standard Tools)

**Use standard tools when:**

1. **Reading full file contents** → Use Read tool (LSP only returns symbol info)
2. **Searching across multiple files for text patterns** → Use Grep tool (not symbol-specific)
3. **Editing or writing files** → Use Edit or Write tools (LSP is read-only)
4. **Non-Ruby files** → Use standard tools (LSP only works with .rb files)
5. **Finding string literals or comments** → Use Grep tool (text search, not semantic)
6. **Understanding project structure (directories, file organization)** → Use Glob, Bash (file system navigation)
7. **Checking for syntax errors** → Use Bash with `ruby -c` (LSP doesn't provide diagnostics endpoint in Claude Code)

## How to Invoke LSP Operations

**Always provide all three required parameters:**

```
LSP operation="goToDefinition" filePath="/path/to/file.rb" line=10 character=15
LSP operation="hover" filePath="/path/to/file.rb" line=20 character=8
LSP operation="documentSymbol" filePath="/path/to/file.rb" line=1 character=1
LSP operation="workspaceSymbol" filePath="/path/to/file.rb" line=1 character=1
LSP operation="findReferences" filePath="/path/to/file.rb" line=15 character=10
```

**Note:** For operations like `documentSymbol` and `workspaceSymbol`, the exact line/character position is less critical, but all parameters are still required.

## Example Workflows

### Task: Understand and modify a Ruby method

1. ✅ Use `documentSymbol` - Get file structure overview
2. ✅ Use `workspaceSymbol` - Find method across project if not in current file
3. ✅ Use `goToDefinition` - Jump to exact method definition
4. ✅ Use `hover` - Understand method signature and docs
5. ✅ Use Read - Get full file content for context
6. ✅ Use `findReferences` - See where method is used
7. ✅ Use `incomingCalls` - See what calls this method
8. ✅ Use `outgoingCalls` - See what this method calls
9. ✅ Use Edit - Make the changes
10. ✅ Use `findReferences` again - Verify impact of changes

### Task: Navigate unfamiliar Ruby codebase

1. ✅ Use `workspaceSymbol` - Search for relevant classes/methods
2. ✅ Use `goToDefinition` - Jump to definitions
3. ✅ Use `hover` - Read documentation
4. ✅ Use `documentSymbol` - Understand file structure
5. ✅ Use `findReferences` - See how symbols are used
6. ✅ Use `incomingCalls`/`outgoingCalls` - Understand call chains

### Task: Refactor a method safely

1. ✅ Use `hover` - Understand current method signature
2. ✅ Use `findReferences` - Find all usages before changing
3. ✅ Use `incomingCalls` - See all callers
4. ✅ Use Edit - Make the refactoring changes
5. ✅ Use `findReferences` - Verify all call sites are updated

## Best Practices

1. **Navigate with LSP** - Use `goToDefinition` instead of searching for method definitions
2. **Understand with hover** - Use `hover` before modifying method calls to see signatures
3. **Verify with references** - Use `findReferences` before and after refactoring
4. **Combine with Read** - Use LSP for structure and navigation, Read for full content
5. **Provide exact positions** - LSP operations require accurate line and character positions
6. **Fall back gracefully** - If LSP calls fail, fall back to standard tools (Read, Grep)

Proactively use these 9 LSP operations throughout your Ruby development workflow for semantic code intelligence.
