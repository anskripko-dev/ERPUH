export interface RequirementBlock {
    headerLine: string;
    name: string;
    raw: string;
}
export interface RequirementsSectionParts {
    before: string;
    headerLine: string;
    preamble: string;
    bodyBlocks: RequirementBlock[];
    after: string;
}
export declare function normalizeRequirementName(name: string): string;
/**
 * Extracts the Requirements section from a spec file and parses requirement blocks.
 */
export declare function extractRequirementsSection(content: string): RequirementsSectionParts;
/**
 * A level-3 header inside `## ADDED`/`## MODIFIED Requirements` that is not a
 * canonical `### Requirement:` header, recorded at the moment the delta reader
 * skips over it. Surfaced as an INFO note by `validate <change>` (#498).
 */
export interface SkippedHeader {
    header: string;
    section: string;
    line: number;
}
export interface DeltaPlan {
    added: RequirementBlock[];
    modified: RequirementBlock[];
    removed: string[];
    renamed: Array<{
        from: string;
        to: string;
    }>;
    skippedHeaders: SkippedHeader[];
    sectionPresence: {
        added: boolean;
        modified: boolean;
        removed: boolean;
        renamed: boolean;
    };
}
/**
 * Parse a delta-formatted spec change file content into a DeltaPlan with raw blocks.
 */
export declare function parseDeltaSpec(content: string): DeltaPlan;
//# sourceMappingURL=requirement-blocks.d.ts.map