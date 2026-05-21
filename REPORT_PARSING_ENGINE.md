# Parsing Logic & Heuristics Audit

## 1. CardParser Scoring System
The parser implements a sophisticated scoring engine rather than simple regex:
- **Positive Boosts**: Proximity to "VALID THRU", "EXPIRY", or "VISA/MASTERCARD" keywords.
- **Negative Penalties**: Proximity to "DOB", "OPEN DATE", or "IFSC" (to distinguish from Passbooks).
- **Luhn Weighting**: Card numbers that pass the Luhn check receive a score multiplier.

## 2. OCR Normalization Pipeline
- **Ligature Handling**: Converts `ﬁ` and `ﬂ` to standard characters.
- **Digit Mapping**: Proactively converts `O -> 0`, `I -> 1`, `S -> 5`, etc.
- **Text Cleaning**: Multi-stage cleaning removes noise and standardizes line breaks before regex execution.

## 3. Passbook Heuristics
- `PassbookParser` successfully identifies IFSC codes with a specific focus on the 5th character (standardized to '0').
- Account number detection uses keyword association (e.g., "A/C NO") to differentiate from transaction amounts.

## 4. Determinism
- Validation confirms **no external parsing libraries** are used. All logic is deterministic Dart code.
