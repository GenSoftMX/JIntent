# Architecture

Applies to library changes and public contracts.

- Review `lib/jintent.dart` and the affected barrels before changing an API;
  identify consumers and tests. Do not remove or change public signatures or
  semantics without authorization for the compatibility impact.
- Keep intent / controller / state / effect separated. Do not bring example
  infrastructure or app-specific services into the core.
- Keep states immutable and `props` consistent with the state data.
- Changes to intent ordering, concurrency, disposal or effect results must define
  the expected behavior and error cases first.
- Check the status of each ADR. Do not treat proposals as accepted decisions or
  silently fix discrepancies between documentation and execution.
- `example/` is a consumer: change it when the scope or a contract change
  requires; do not make its architecture a requirement for the whole library.
