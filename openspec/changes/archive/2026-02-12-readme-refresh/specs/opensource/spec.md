## MODIFIED Requirements

### Requirement: English Documentation
The system SHALL have English documentation for international users. The README structure and content SHALL follow the rules defined in `docs/readme-guide.md`.

#### Scenario: README in English
- **GIVEN** a user visits the GitHub repository
- **WHEN** they view the README
- **THEN** all content is in English
- **AND** installation instructions are provided for all supported platforms

#### Scenario: README follows guide
- **GIVEN** the `docs/readme-guide.md` exists
- **WHEN** the README is created or updated
- **THEN** it follows the mandatory section structure defined in the guide
- **AND** all user-facing CLI tools are documented
