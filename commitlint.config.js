module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Enforce conventional commit types
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation only
        'style',    // Formatting, no code change
        'refactor', // Code change that neither fixes nor adds
        'perf',     // Performance improvement
        'test',     // Adding or modifying tests
        'build',    // Build system or dependencies
        'ci',       // CI configuration
        'chore',    // Maintenance tasks
        'revert',   // Revert a previous commit
      ],
    ],
    // Require lowercase type
    'type-case': [2, 'always', 'lower-case'],
    // Require non-empty subject
    'subject-empty': [2, 'never'],
    // Require type
    'type-empty': [2, 'never'],
  },
};
