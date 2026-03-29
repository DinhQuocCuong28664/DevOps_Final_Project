export default [
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        __dirname: "readonly",
        __filename: "readonly",
        module: "readonly",
        require: "readonly",
        exports: "readonly",
        process: "readonly",
        console: "readonly",
        Buffer: "readonly",
        setTimeout: "readonly",
        setInterval: "readonly",
        clearTimeout: "readonly",
        clearInterval: "readonly",
      },
    },
    rules: {
      // Bắt lỗi nghiêm trọng
      "no-undef": "error",
      "no-constant-condition": "error",
      "no-dupe-keys": "error",
      "no-duplicate-case": "error",
      "no-unreachable": "error",
      "use-isnan": "error",
      "valid-typeof": "error",
      // Cảnh báo code quality
      "no-unused-vars": "warn",
      "no-var": "warn",
      "prefer-const": "warn",
    },
  },
  {
    ignores: ["node_modules/", "public/", "uploads/"],
  },
];
