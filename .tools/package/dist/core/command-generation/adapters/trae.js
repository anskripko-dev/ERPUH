/**
 * Trae Command Adapter
 *
 * Formats commands for Trae IDE following its command specification.
 */
import path from 'path';
/**
 * Escapes a string value for safe YAML output.
 * Quotes the string if it contains special YAML characters.
 */
function escapeYamlValue(value) {
    if (value === '') {
        return '""';
    }
    // Check if value needs quoting (contains special YAML characters or starts/ends with whitespace)
    const needsQuoting = /[:\n\r#{}[\],&*!|>'"%@`]|^\s|\s$/.test(value);
    if (needsQuoting) {
        // Use double quotes and escape internal double quotes, backslashes, and newlines
        const escaped = value
            .replace(/\\/g, '\\\\')
            .replace(/"/g, '\\"')
            .replace(/\n/g, '\\n')
            .replace(/\r/g, '\\r');
        return `"${escaped}"`;
    }
    return value;
}
/**
 * Trae adapter for command generation.
 * File path: .trae/commands/opsx-<id>.md
 * Frontmatter: name, description
 */
export const traeAdapter = {
    toolId: 'trae',
    getFilePath(commandId) {
        return path.join('.trae', 'commands', `opsx-${commandId}.md`);
    },
    formatFile(content) {
        return `---
name: ${escapeYamlValue(content.name)}
description: ${escapeYamlValue(content.description)}
---

${content.body}
`;
    },
};
//# sourceMappingURL=trae.js.map