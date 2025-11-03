# OptiPlant Documentation System - Technical Guide

This guide explains how the OptiPlant documentation system works, how to maintain it, and what each component does. This is a technical reference for collaborators working on documentation.

## Overview

The OptiPlant documentation uses **Documenter.jl**, a Julia-specific documentation generator that creates professional HTML documentation from Markdown source files. The system is inspired by CSV.jl's documentation structure and follows Julia package documentation best practices.

## File Structure and Components

### Core Documentation Files

```
docs/
├── make.jl                 # Build script - generates HTML from Markdown
├── Project.toml           # Julia environment for documentation
├── Manifest.toml          # Locked dependencies
├── src/                   # Source Markdown files
│   ├── index.md          # Main landing page
│   ├── installation.md   # Installation guide
│   ├── usage.md          # Usage documentation
│   ├── Examples.md       # Examples and tutorials
│   └── api.md            # API reference
└── build/                # Generated HTML files (auto-created)
    ├── index.html
    ├── installation.html
    ├── usage.html
    ├── Examples.html
    └── api.html
```

### Key Files Explained

#### `docs/make.jl` - The Build Engine
This is the heart of the documentation system. It:
- Configures Documenter.jl settings
- Defines the site structure and navigation
- Handles GitHub Pages deployment
- Sets up cross-references and linking

**Key sections:**
```julia
makedocs(
    sitename = "OptiPlant.jl",           # Website title
    format = Documenter.HTML(...),       # Output format
    pages = [                            # Navigation structure
        "Home" => "index.md",
        "Installation" => "installation.md",
        # ... more pages
    ]
)
```

#### `docs/src/index.md` - Landing Page
The main entry point that visitors see first. Contains:
- Project overview and description
- Quick installation instructions
- Navigation to other sections
- GitHub repository links and badges

#### `docs/src/installation.md` - Installation Guide
Comprehensive setup instructions including:
- Prerequisites (Julia version, system requirements)
- Package installation methods
- Solver configuration (HiGHS, Gurobi, CPLEX)
- Troubleshooting common issues
- Verification steps

#### `docs/src/usage.md` - Usage Documentation
Detailed guide for using OptiPlant:
- Basic concepts and workflow
- Configuration options
- Multi-scenario analysis
- Advanced features
- Best practices

#### `docs/src/Examples.md` - Examples and Tutorials
Practical examples organized by use case:
- Technology comparisons
- Location assessments
- Dashboard setup
- Real-world scenarios

#### `docs/src/api.md` - API Reference
Technical reference documentation:
- Function signatures
- Data structures
- Module documentation
- Parameter descriptions

## Documentation Workflow

### 1. Local Development

#### Building Documentation Locally
```bash
# Navigate to project root
cd C:\Users\sebas\OneDrive\Desktop\Optiplant\OptiPlant

# Build documentation
julia --project=docs docs/make.jl
```

This generates HTML files in `docs/build/` that you can open in a browser to preview changes.

#### Making Changes
1. Edit Markdown files in `docs/src/`
2. Run build command to generate HTML
3. Check `docs/build/index.html` in browser
4. Iterate until satisfied

### 2. GitHub Pages Deployment

#### Current Setup (Manual Deployment)
We use a **manual gh-pages branch approach** instead of GitHub Actions because:
- More reliable for complex Julia packages
- Better control over deployment timing
- Avoids dependency conflicts in CI

#### Deployment Process
1. **Build locally**: `julia --project=docs docs/make.jl`
2. **Switch to gh-pages branch**: `git checkout gh-pages`
3. **Copy build files**: Copy all files from `docs/build/` to root
4. **Commit and push**: 
   ```bash
   git add .
   git commit -m "Update documentation"
   git push origin gh-pages
   ```

#### GitHub Pages Configuration
In GitHub repository settings:
- **Source**: Deploy from a branch
- **Branch**: gh-pages
- **Folder**: / (root)

### 3. Branch Strategy

- **Development branch**: All documentation source files and changes
- **gh-pages branch**: Only contains built HTML files for GitHub Pages
- **Main branch**: Stable releases (documentation changes merge here eventually)

## Content Guidelines

### Writing Style
Follow CSV.jl documentation style:
- Clear, concise explanations
- Practical examples with code blocks
- Cross-references between sections
- Professional but accessible tone

### Markdown Features
Documenter.jl supports enhanced Markdown:
- Code blocks with syntax highlighting
- Cross-references: `[Installation](@ref)`
- Math equations: `$x^2 + y^2 = z^2$`
- Admonitions: `!!! note`, `!!! warning`
- Auto-generated API docs

### Navigation Structure
The `pages` array in `make.jl` defines:
- Menu order in the sidebar
- URL structure
- Page hierarchy

## Maintenance Tasks

### Regular Updates
1. **Keep examples current**: Update examples when API changes
2. **Refresh installation instructions**: Update Julia/package versions
3. **Add new features**: Document new functionality in usage/API sections
4. **Fix broken links**: Check internal and external links periodically

### Troubleshooting Common Issues

#### Build Failures
- **Missing dependencies**: Check `docs/Project.toml`
- **Broken cross-references**: Verify `@ref` tags point to existing sections
- **Julia version conflicts**: Ensure compatibility

#### GitHub Pages Not Updating
- **Check branch**: Ensure gh-pages branch has latest HTML files
- **Verify settings**: Confirm GitHub Pages source configuration
- **Clear cache**: Sometimes browser caching causes confusion

#### Formatting Issues
- **Markdown syntax**: Documenter.jl has specific requirements
- **Code blocks**: Use proper language tags (```julia, ```bash)
- **Math equations**: Check LaTeX syntax in `$...$` blocks

## Advanced Features

### Auto-Generated API Documentation
Documenter.jl can automatically extract docstrings from Julia code:
```markdown
```@docs
function_name
```

### Custom Themes and Styling
The HTML output can be customized through:
- CSS modifications in `make.jl`
- Custom themes
- Asset files (logos, icons)

### Search Functionality
Built-in search is automatically generated from content.

## Integration with Development Workflow

### When to Update Documentation
- **New features**: Document immediately when adding functionality
- **API changes**: Update signatures and examples
- **Bug fixes**: Clarify usage if bugs caused confusion
- **Release cycles**: Comprehensive review before major releases

### Collaboration Guidelines
1. **Edit on Development branch**: Never edit gh-pages directly
2. **Preview locally**: Always build and check before committing
3. **Clear commit messages**: Describe documentation changes specifically
4. **Cross-reference PRs**: Link documentation updates to code changes

## Tools and Dependencies

### Required Software
- **Julia**: Version 1.6+ (current project uses 1.10+)
- **Git**: For version control and GitHub Pages deployment
- **Web browser**: For previewing documentation

### Julia Packages
- **Documenter.jl**: Documentation generator (v1.15.0)
- **DocumenterTools.jl**: Additional utilities (optional)

### External Services
- **GitHub Pages**: Free hosting for public repositories
- **GitHub**: Version control and collaboration platform

## Best Practices

### Content Organization
- **One topic per page**: Don't mix installation with usage examples
- **Progressive complexity**: Start simple, build to advanced topics
- **Cross-link heavily**: Help users navigate between related topics

### Code Examples
- **Complete and runnable**: Examples should work copy-paste
- **Explain the why**: Don't just show code, explain the purpose
- **Use realistic data**: Examples should reflect real use cases

### Maintenance
- **Version everything**: Keep documentation in sync with code versions
- **Test examples**: Regularly verify that examples still work
- **Monitor feedback**: Watch for user confusion or questions

## Conclusion

This documentation system provides a professional, maintainable foundation for OptiPlant.jl. The combination of Documenter.jl, GitHub Pages, and careful content organization creates documentation that serves both new users and experienced developers.

The key to success is regular maintenance, clear writing, and keeping documentation synchronized with code changes. When in doubt, follow the patterns established by successful Julia packages like CSV.jl, DataFrames.jl, and Plots.jl.