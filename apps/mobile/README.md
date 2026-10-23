# Supply Biz Mobile

Flutter entrypoints are `lib/main_dev.dart`, `lib/main_staging.dart`, and
`lib/main_prod.dart`. Use the matching native flavor/scheme and
`config/<flavor>.json` when running or building. Firebase is opt-in per
flavor; see
[`ENVIRONMENT_SETUP.md`](../../docs/06-development/ENVIRONMENT_SETUP.md) for
required native configuration files.
