## MODIFIED Requirements

### Requirement: Design review includes component structure checks
The `build_design_review_section()` SHALL include a "Component Structure" subsection when Figma source files are available. This subsection SHALL list key UI patterns found in source files: icon imports, image dimensions, layout containers. The reviewer SHALL compare these against the diff and report mismatches as [WARNING].

#### Scenario: Source files show ShoppingBag icon for cart
- **WHEN** Figma source `Navbar.tsx` imports `ShoppingBag` from lucide-react for the cart link
- **AND** the diff uses text "Cart" without any icon
- **THEN** the review SHALL report: `[WARNING] Design uses ShoppingBag icon for cart nav — implementation uses plain text`

#### Scenario: Source files show product thumbnail in admin table
- **WHEN** Figma source `AdminProducts.tsx` renders `w-12 h-12` image thumbnails in the product table
- **AND** the diff has a product table without image column
- **THEN** the review SHALL report: `[WARNING] Design includes product thumbnail (w-12 h-12) in admin table — implementation omits image`

#### Scenario: No source files available
- **WHEN** no `docs/figma-raw/*/sources/` directory exists
- **THEN** the review section SHALL contain only token checks (existing behavior unchanged)

### Requirement: Icon usage checklist extraction
The bridge SHALL parse Figma source files for lucide-react icon imports and build a checklist of "Component → Icon" mappings. This checklist SHALL be appended to the review section.

#### Scenario: Multiple icons across source files
- **WHEN** source files contain `import { ShoppingBag, Package, Pencil, Trash2, Plus } from 'lucide-react'`
- **THEN** the review section SHALL include an "Icon Usage" checklist listing each icon and which component uses it

### Requirement: Design review severity remains WARNING
All component structure mismatches SHALL be reported as [WARNING], not [CRITICAL]. Design compliance is advisory — functional correctness takes priority.

#### Scenario: Multiple structure mismatches found
- **WHEN** 3 component structure mismatches are found (missing icon, missing thumbnail, wrong heading size)
- **THEN** all three SHALL be reported as [WARNING]
- **AND** the review SHALL NOT fail the gate
