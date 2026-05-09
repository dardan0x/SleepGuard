#!/usr/bin/env python3
import json, os, re, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)

XCSTRINGS = os.path.join(ROOT, "Packages/DesignSystem/Sources/Resources/Localizable.xcstrings")
OUTPUT = os.path.join(ROOT, "Packages/DesignSystem/Sources/Strings.swift")

NUMBER_WORDS = {
    '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
    '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
    '10': 'ten', '11': 'eleven', '12': 'twelve', '500': 'fiveHundred',
}

RESERVED = {
    'default', 'switch', 'case', 'return', 'break', 'continue',
    'var', 'let', 'func', 'class', 'struct', 'enum', 'import',
    'protocol', 'extension', 'self', 'super', 'init', 'deinit',
}


def base_name(key: str) -> str:
    """Generate a base identifier from a localization key."""
    # Replace format specifiers with semantic placeholders
    text = key
    text = re.sub(r'%.0f%%', ' percent ', text)
    text = re.sub(r'%.0f', ' value ', text)
    text = re.sub(r'%f', ' value ', text)
    text = re.sub(r'%lld', ' count ', text)
    text = re.sub(r'%d', ' count ', text)
    text = re.sub(r'%@', ' value ', text)

    # Remove punctuation
    text = text.replace("'", '').replace("'", '')
    text = text.replace("—", ' ').replace("–", ' ')
    text = text.replace("·", ' ').replace("/", ' ').replace("-", ' ')
    text = text.replace("(", ' ').replace(")", ' ').replace(">", '')
    text = text.replace("?", '').replace("!", '').replace(",", '')
    text = text.replace(".", ' ').replace('"', '').replace(";", '')

    # Remove emojis and non-alphanumeric
    text = ''.join(c if c.isalnum() or c.isspace() else ' ' for c in text)

    # Split camelCase words (e.g. "buttonPrimary" → "button Primary")
    text = re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', text)

    words = text.split()
    if not words:
        return "string"

    # Process words
    processed = []
    for word in words:
        if word in NUMBER_WORDS:
            processed.append(NUMBER_WORDS[word])
        elif word.isupper() and len(word) > 1:
            processed.append(word.lower())
        else:
            processed.append(word.lower())

    # Preserve kHz casing
    for i, word in enumerate(processed):
        if word == 'khz':
            processed[i] = 'kHz'

    # Build camelCase
    result = processed[0]
    for word in processed[1:]:
        result += word.capitalize()

    # Detect format strings by placeholder words (but not if key already encodes it)
    if 'count' in processed or 'value' in processed or 'percent' in processed:
        if not result.endswith('Format'):
            result += 'Format'

    if len(result) <= 1:
        result += 'String'

    if result in RESERVED:
        result += 'String'

    return result


def disambiguate(names: dict[str, str]) -> dict[str, str]:
    """Resolve naming conflicts by appending contextual suffixes."""
    groups: dict[str, list[str]] = {}
    for key, name in names.items():
        groups.setdefault(name, []).append(key)

    final: dict[str, str] = {}
    for name, group_keys in groups.items():
        if len(group_keys) == 1:
            final[group_keys[0]] = name
            continue

        for key in group_keys:
            words = [w for w in key.split() if w.isalpha()]
            has_all_caps = any(w.isupper() and len(w) > 1 for w in words)
            sig_words = [w for w in words if len(w) > 2]
            is_title_case = (
                len(sig_words) > 1
                and sig_words[0][0].isupper()
                and all(w[0].isupper() for w in sig_words[1:])
            )
            is_sentence_case = (
                len(sig_words) > 1
                and sig_words[0][0].isupper()
                and all(w[0].islower() for w in sig_words[1:])
            )

            suffix = ""
            if key.endswith('?'):
                suffix = "Question"
            elif is_title_case and not is_sentence_case:
                suffix = "Title"
            elif has_all_caps:
                suffix = "Upper"

            if not suffix:
                suffix = f"{len(key.split())}Words"

            # Insert suffix before trailing 'Format' for readability
            if name.endswith('Format'):
                final[key] = name[:-6] + suffix + 'Format'
            else:
                final[key] = name + suffix

    return final


def main():
    with open(XCSTRINGS, "r") as f:
        catalog = json.load(f)

    keys = catalog.get("strings", {})

    # First pass: base names
    base = {key: base_name(key) for key in keys}

    # Second pass: disambiguate conflicts
    final = disambiguate(base)

    # Verify no conflicts remain
    seen: dict[str, str] = {}
    for key, name in final.items():
        if name in seen:
            print(f"error: unresolved conflict '{name}' for '{seen[name]}' and '{key}'")
            sys.exit(1)
        seen[name] = key

    lines = [
        "import Foundation",
        "",
        "/// Auto-generated from Localizable.xcstrings — do not edit manually.",
        "/// Run: python3 scripts/generate-strings.py",
        "public enum Strings {",
    ]

    for key in sorted(keys.keys()):
        name = final[key]
        escaped = key.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'  public static var {name}: String {{ String(localized: "{escaped}", bundle: .module) }}')

    lines.append("}")
    output = "\n".join(lines) + "\n"

    existing = ""
    if os.path.exists(OUTPUT):
        with open(OUTPUT, "r") as f:
            existing = f.read()

    if existing == output:
        print("Strings.swift is up-to-date.")
        return

    with open(OUTPUT, "w") as f:
        f.write(output)
    print(f"Generated {OUTPUT} with {len(keys)} strings.")

    # Report long names
    long_names = [(k, final[k]) for k in final if len(final[k]) > 40]
    if long_names:
        print(f"\nNote: {len(long_names)} names are >40 chars:")
        for key, name in sorted(long_names, key=lambda x: -len(x[1]))[:10]:
            print(f"  {name} ({len(name)} chars)")


if __name__ == "__main__":
    main()
