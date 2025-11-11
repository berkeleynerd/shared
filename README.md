gps_shared (draft crate)

Purpose
- Provides the shared GPR project (GPS_Shared) containing compiler/linker
  switches used across GNAT Studio core crates.

Status
- This is a draft manifest for splitting into its own repository.
- In this monorepo the alire manifest points to ../../gps_shared.gpr.
  When extracting into a standalone repo, place gps_shared.gpr at the repo
  root and update project-files accordingly.

Dependencies
- gnatcoll: required by the GPR includes used by dependent crates.

Build (after split)
- alr build -- -P gps_shared.gpr

