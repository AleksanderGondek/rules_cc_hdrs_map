# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## v0.20.1 - 2025-08-08
#### Bug Fixes
- **(make-variables_expansion)** will no longer trigger Bazel error - (d1371d0) - Aleksander Gondek

- - -

## v0.20.0 - 2025-08-07
#### Features
- **(cc_sources)** add extra extensions allowed - (0966786) - Aleksander Gondek

- - -

## v0.19.0 - 2025-08-04
#### Features
- **(hdrs_map_info)** gather HdrsMapInfo transitively - (10af2ce) - Aleksander Gondek

- - -

## v0.18.1 - 2025-08-04
#### Bug Fixes
- **(hdrs_map_info)** merge_hdrs_map_infos not working - (4d85291) - Aleksander Gondek

- - -

## v0.18.0 - 2025-08-03
#### Features
- **(providers_helper.bzl)** publicize common providers operations - (514f240) - Aleksander Gondek

- - -

## v0.17.0 - 2025-08-02
#### Features
- **(nix-shell)** starpls capability to use bazel - (cd288cd) - Aleksander Gondek

- - -

## v0.16.0 - 2025-08-02
#### Features
- **(nixpkgs)** update definitions to latest as of 2025-08-02 - (82b59e5) - Aleksander Gondek

- - -

## v0.15.0 - 2025-08-01
#### Features
- **(cc_archive)** switch to cc_common implementation - (c0817f4) - Aleksander Gondek

- - -

## v0.14.0 - 2025-07-28
#### Features
- **(attrs)** notify user if using not implemented attrs - (432d336) - Aleksander Gondek

- - -

## v0.13.4 - 2025-07-28
#### Bug Fixes
- **(additional_inputs)** properly gather items - (e562841) - Aleksander Gondek

- - -

## v0.13.3 - 2025-07-26
#### Bug Fixes
- **(attrs)** adjust attributes of rules - (7032eec) - Aleksander Gondek

- - -

## v0.13.2 - 2025-07-26
#### Bug Fixes
- **(attrs)** allow raw files in additional inputs - (858bc7b) - Aleksander Gondek

- - -

## v0.13.1 - 2025-07-20
#### Bug Fixes
- **(cc_archive|cc_so)** too eager name cleaning - (769f01f) - Aleksander Gondek

- - -

## v0.13.0 - 2025-07-20
#### Features
- **(cc_archive)** custom name of the output archive - (446ce39) - Aleksander Gondek

- - -

## v0.12.0 - 2025-07-20
#### Features
- **(rules)** support for raw fiels in data attr - (60b89eb) - Aleksander Gondek

- - -

## v0.11.0 - 2025-07-18
#### Features
- **(actions)** expose prepare_for_compilarion as utility of ruleset - (9112876) - Aleksander Gondek

- - -

## v0.10.0 - 2025-07-17
#### Features
- **(hdrs_map)** optimize the peformance - (747fbb1) - Aleksander Gondek

- - -

## v0.9.2 - 2025-07-17
#### Bug Fixes
- **(depset)** reduce and improve iteration approach - (5a33411) - Aleksander Gondek

- - -

## v0.9.1 - 2025-07-16
#### Bug Fixes
- **(cc_helper)** make variables substitutions - (44af14f) - Aleksander Gondek
- **(cc_helper)** '.c' source file extension represented - (e82a140) - Aleksander Gondek
- **(link_to_so)** failing on 'link_once_static_libs' being None - (e6577ca) - Aleksander Gondek
- **(runfiles)** default propagation - (4d07cbb) - Aleksander Gondek

- - -

## v0.9.0 - 2025-07-15
#### Features
- **(deps)** update rules_cc to 0.1.3 - (276e857) - Aleksander Gondek

- - -

## v0.8.1 - 2025-07-15
#### Bug Fixes
- **(cog)** bumping of project version in MODULE.bazel files - (e59e356) - Aleksander Gondek

- - -

## v0.8.0 - 2025-07-15
#### Features
- **(compile)** treat hdrs from srcs as implementation hdrs - (0e68b00) - Aleksander Gondek
#### Refactoring
- default runfiles handling - (fc1e5cc) - Aleksander Gondek
#### Tests
- **(examples)** extended the simple targets - (c3e9e13) - Aleksander Gondek

- - -

## v0.7.0 - 2025-07-14
#### Features
- **(compile)** improve compile action implementation - (ab06851) - Aleksander Gondek

- - -

## v0.6.1 - 2025-07-14
#### Bug Fixes
- **(cc_bin)** defintions of attrs for link_to_bin action - (5a216a2) - Aleksander Gondek

- - -

## v0.6.0 - 2025-07-14
#### Features
- **(hdrs_map)** rename atrributes to align with rules_cc - (a9c9e0f) - Aleksander Gondek

- - -

## v0.5.1 - 2025-07-14
#### Bug Fixes
- **(cc_so)** defintions of attrs for link_to_so action - (e8bc4b7) - Aleksander Gondek

- - -

## v0.5.0 - 2025-07-14
#### Features
- **(cc_so)** opinionated sol names - (152cfd6) - Aleksander Gondek

- - -

## v0.4.0 - 2025-07-11
#### Features
- **(cc_so)** implement actual linking with cutoff - (3d2520b) - Aleksander Gondek

- - -

## v0.3.1 - 2025-07-11
#### Bug Fixes
- **(hdrs_map.bzl)** pattern match and actions duplication - (4c266e5) - Aleksander Gondek

- - -

## v0.3.0 - 2025-07-10
#### Bug Fixes
- **(bazelrc)** disable repo_contents_cache - (14d1c1f) - Aleksander Gondek
#### Features
- **(update)** dependencies to latest as of 2025-07-10 - (4ffe6b0) - Aleksander Gondek

- - -

## v0.2.0 - 2025-05-24
#### Build system
- **(cog)** keep the examples version synced - (4df18f8) - Aleksander Gondek
#### Continuous Integration
- **(gh-actions)** automatically create release archive - (454d15d) - Aleksander Gondek
#### Features
- **(update)** dependencies to latest as of 2025-05-24 - (3d4cf12) - Aleksander Gondek

- - -

## v0.1.0 - 2025-04-30
#### Features
- cc compilation/linking as bazel subrules - (7bc201b) - Aleksander Gondek

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).