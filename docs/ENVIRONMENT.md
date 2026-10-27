# Local environment

Machine paths live in ignored .local/environment.json. .local contains owner-specific copied candidates, rollback, evidence and research inputs. Original immutable manifests retain their historical paths; consult current docs/STATUS.md rather than treating a historical pending field as current acceptance. No historical installer is executed by this migration.

UE4SS/UEHelpers, game files, extracted HTML, fonts, repak/retoc/CUE4Parse and test libraries are external dependencies, not vendored source. See LOCAL_DEPENDENCIES.md. Local app project registration is separate from Git/GitHub; existing historical projects are not silently redirected.
