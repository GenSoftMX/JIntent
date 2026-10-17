# Dart style

- Follow `analysis_options.yaml`, Dart formatting and nearby conventions.
- Keep explicit types in public contracts; avoid `dynamic` and casts that hide
  null-safety or generics errors.
- Keep names and public documentation in the language of the existing code.
- Do not mix mass reformatting, renames or generated files with unrelated
  functional changes. Do not add dependencies beyond what the scope needs.
- When changing asynchronous code, define who awaits, who catches errors and who
  releases resources. Document limitations that are part of the contract.
