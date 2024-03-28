# Changelog

## [2.1.0](https://github.com/pysan3/pathlib.nvim/compare/v2.0.1...v2.1.0) (2024-03-28)


### Bug Fixes

* **base:** fix suffix detection and add tests ([#54](https://github.com/pysan3/pathlib.nvim/issues/54)) ([25d2123](https://github.com/pysan3/pathlib.nvim/commit/25d2123fd3c4e0548b7c7678ad54fed5a9b7be78))


### Documentation

* **base:** fix and improve docs for `self:with_suffix` ([7a5be95](https://github.com/pysan3/pathlib.nvim/commit/7a5be954bb950ec7b3dbacd05c75e7a38287a817))

## [2.0.1](https://github.com/pysan3/pathlib.nvim/compare/v2.0.0...v2.0.1) (2024-03-28)


### Bug Fixes

* **base:** fix resolving multiple `../` and add test ([#52](https://github.com/pysan3/pathlib.nvim/issues/52)) ([6fb37e0](https://github.com/pysan3/pathlib.nvim/commit/6fb37e0fbd0df1fb3cd81942d9992ef6fc2406b3))

## [2.0.0](https://github.com/pysan3/pathlib.nvim/compare/v1.1.1...v2.0.0) (2024-03-26)


### ⚠ BREAKING CHANGES

* **base:** move Path.len -> depth to make path align with string.len ([#50](https://github.com/pysan3/pathlib.nvim/issues/50))

### Features

* **base:** move Path.len -&gt; depth to make path align with string.len ([#50](https://github.com/pysan3/pathlib.nvim/issues/50)) ([43cc27c](https://github.com/pysan3/pathlib.nvim/commit/43cc27c2868c9dd0afe5a4c651d520a505bf3b4a))

## [1.1.1](https://github.com/pysan3/pathlib.nvim/compare/v1.1.0...v1.1.1) (2024-03-26)


### Bug Fixes

* **base:** fix `self:child` when self:len() == 0 returns wrong string cache ([4664793](https://github.com/pysan3/pathlib.nvim/commit/466479340e21c2a6d7c3459cf2d958b0551d692a))
* **init:** trick type annotations ([48f9d2b](https://github.com/pysan3/pathlib.nvim/commit/48f9d2b35e60f7b3fa66b6071360e47483ba587e))

## [1.1.0](https://github.com/pysan3/pathlib.nvim/compare/v1.0.2...v1.1.0) (2024-03-25)


### Features

* **base:** add peek to get specific part in path ([#45](https://github.com/pysan3/pathlib.nvim/issues/45)) ([5511eb3](https://github.com/pysan3/pathlib.nvim/commit/5511eb3b077e53a310bce9a3192d7817b702f160))
* **base:** make path object inherit string manipulation functions ([fe5cd85](https://github.com/pysan3/pathlib.nvim/commit/fe5cd85a509c6756cd98fcf0fd59d5f0d0c636c2))

## [1.0.2](https://github.com/pysan3/pathlib.nvim/compare/v1.0.1...v1.0.2) (2024-03-21)


### Bug Fixes

* **base:** add `with_stem` variants ([f912333](https://github.com/pysan3/pathlib.nvim/commit/f912333cb7c9e07e26ab1309381c469446208b08))
* **base:** deprecate siblings with concat ([47b0cd9](https://github.com/pysan3/pathlib.nvim/commit/47b0cd9964fc821b22b2cbc7d289291ed99d4381))
* **base:** rename `new_descendant` to `descendant` for simplicity ([f8b8281](https://github.com/pysan3/pathlib.nvim/commit/f8b8281f97e90c753552b2ba8c6e28e9cf5dba19))
* **types:** add type annotations for operator overload ([d194dc2](https://github.com/pysan3/pathlib.nvim/commit/d194dc2af8aee76ac1d1bbd6164eb6cd0dc0d23d))

## [1.0.1](https://github.com/pysan3/pathlib.nvim/compare/v1.0.0...v1.0.1) (2024-03-21)


### Bug Fixes

* **base:** add string concat mode to make it work with old code ([#40](https://github.com/pysan3/pathlib.nvim/issues/40)) ([6e7219f](https://github.com/pysan3/pathlib.nvim/commit/6e7219fcaf5956fa5acfaffd1ff59876d1b001e8))
* **base:** return self from `to_absolute` for easier chaining ([#42](https://github.com/pysan3/pathlib.nvim/issues/42)) ([b8d3184](https://github.com/pysan3/pathlib.nvim/commit/b8d3184a55806472ee303b263658b40524dd8c1b))

## [1.0.0](https://github.com/pysan3/pathlib.nvim/compare/v0.6.5...v1.0.0) (2024-03-18)


### ⚠ BREAKING CHANGES

* release first major version
* release first major version

### Features

* release first major version ([44e3a10](https://github.com/pysan3/pathlib.nvim/commit/44e3a10ece63a145530bc2b7c8603eaf7a7152f5))
* release first major version ([1a5b9c5](https://github.com/pysan3/pathlib.nvim/commit/1a5b9c5dc3f00c15d8f33eb1642618952588e804))

## [0.6.5](https://github.com/pysan3/pathlib.nvim/compare/v0.6.4...v0.6.5) (2024-03-15)


### Bug Fixes

* **scheduler:** make sure to sleep more than enough to trigger the task ([3a65f03](https://github.com/pysan3/pathlib.nvim/commit/3a65f03f8748552a08ac03aebf8e437c0c48b091))

## [0.6.4](https://github.com/pysan3/pathlib.nvim/compare/v0.6.3...v0.6.4) (2024-03-15)


### Bug Fixes

* **git:** allow path to not have `git_state` to request ([fb7f23b](https://github.com/pysan3/pathlib.nvim/commit/fb7f23b56ea3cea340e1b627c4216bd42570fc47))

## [0.6.3](https://github.com/pysan3/pathlib.nvim/compare/v0.6.2...v0.6.3) (2024-02-22)


### Bug Fixes

* **base:** fix shellescape to work on Windows ([b82db08](https://github.com/pysan3/pathlib.nvim/commit/b82db08e3889dc3d93e204f169cc09cb40c38182))
* **base:** update document for shellescape to be correct ([c13bd05](https://github.com/pysan3/pathlib.nvim/commit/c13bd05b9775b18e5fddbb96b76f3b80c9d5148d))

## [0.6.2](https://github.com/pysan3/pathlib.nvim/compare/v0.6.1...v0.6.2) (2024-02-22)


### Bug Fixes

* **base:** fix wrong comparison in string generation ([9d384f3](https://github.com/pysan3/pathlib.nvim/commit/9d384f38548dfc6159131897da98a7dd162e4cbb))

## [0.6.1](https://github.com/pysan3/pathlib.nvim/compare/v0.6.0...v0.6.1) (2024-02-21)


### Bug Fixes

* **base:** fix type issue and wrong initialization ([3e95f11](https://github.com/pysan3/pathlib.nvim/commit/3e95f11a35fd0f5bdc619622c00583d5d986759f))
* **git:** add scheduler to debounce git status checks ([a27ce38](https://github.com/pysan3/pathlib.nvim/commit/a27ce38ce8f42716c6e615cf757c8a7437320a25))
* **git:** make sure scheduler is always triggered at least once ([5f3cbe4](https://github.com/pysan3/pathlib.nvim/commit/5f3cbe48ad61c36180f77cffa35167b8083a1582))
* **git:** process git ignore checks in batches to avoid error ([c9a8812](https://github.com/pysan3/pathlib.nvim/commit/c9a88123c4bb54b126c491037a41c33761d7ce38))

## [0.6.0](https://github.com/pysan3/pathlib.nvim/compare/v0.5.4...v0.6.0) (2024-02-19)


### Features

* **git:** use nio.process to fetch git state inside nio job ([#32](https://github.com/pysan3/pathlib.nvim/issues/32)) ([f754df5](https://github.com/pysan3/pathlib.nvim/commit/f754df5748b612283dc6f0d3c929cab96661dd5a))

## [0.5.4](https://github.com/pysan3/pathlib.nvim/compare/v0.5.3...v0.5.4) (2024-02-18)


### Bug Fixes

* **base:** fs_iterdir bug when skip_dir is nil ([da7f101](https://github.com/pysan3/pathlib.nvim/commit/da7f101f2c12d85fe7d45ec2a7f1301c207a13d8))

## [0.5.3](https://github.com/pysan3/pathlib.nvim/compare/v0.5.2...v0.5.3) (2024-02-18)


### Bug Fixes

* **type:** add type annotation to Path() as a function call ([e463807](https://github.com/pysan3/pathlib.nvim/commit/e4638072f1b1677f91b139945df7b5cd93999b81))

## [0.5.2](https://github.com/pysan3/pathlib.nvim/compare/v0.5.1...v0.5.2) (2024-02-18)


### Bug Fixes

* **base:** add `cmd_string` and `shell_string` for special usecase ([4b6b503](https://github.com/pysan3/pathlib.nvim/commit/4b6b5035bfecf6b557658ad42e4fdaf2075c17da))
* **base:** add `parent_assert` and deprecate `parent_string` ([6169fea](https://github.com/pysan3/pathlib.nvim/commit/6169feac2aa2482906898e8ad1ec9a8a5adbeb5c))
* **base:** add ability to specify separator with `:tostring` ([0bf7423](https://github.com/pysan3/pathlib.nvim/commit/0bf7423e4f5a5afeac9287e2a2629c27e4d4e324))
* **uri:** support uri path parsing with `Path.from_uri` ([1d60086](https://github.com/pysan3/pathlib.nvim/commit/1d600865ae4c821778d253101ff89b6f6514ce53))

## [0.5.1](https://github.com/pysan3/pathlib.nvim/compare/v0.5.0...v0.5.1) (2024-02-16)


### Bug Fixes

* **base:** fix docstring to render correctly in docs ([72e5167](https://github.com/pysan3/pathlib.nvim/commit/72e5167b3040d4f4725f5b95f5129a50a2a94e34))

## [0.5.0](https://github.com/pysan3/pathlib.nvim/compare/v0.4.2...v0.5.0) (2024-02-16)


### Features

* **base:** add methods to calculate relativity ([d92854b](https://github.com/pysan3/pathlib.nvim/commit/d92854b004903d59c4bb8530d75ed2954ad73cbf))

## [0.4.2](https://github.com/pysan3/pathlib.nvim/compare/v0.4.1...v0.4.2) (2024-02-14)


### Bug Fixes

* **base:** add more convinient methods ([5c67e6d](https://github.com/pysan3/pathlib.nvim/commit/5c67e6d4a03fea9d19fa3c7f5dd9ccab5617290e))
* **git:** fix code gathering git_roots of paths ([7921607](https://github.com/pysan3/pathlib.nvim/commit/7921607e9201f8d7a30ec2065657157adff18ad4))
* **type:** add fake meta file for luassert type annotation ([f99b4c4](https://github.com/pysan3/pathlib.nvim/commit/f99b4c436dd684addfab138e6ecd4d19e1008004))

## [0.4.1](https://github.com/pysan3/pathlib.nvim/compare/v0.4.0...v0.4.1) (2024-02-02)


### Bug Fixes

* **iterdir:** optimize fs_iterdir performance ([69d313a](https://github.com/pysan3/pathlib.nvim/commit/69d313ab70c75833d8e854641ff96d883584bed9))

## [0.4.0](https://github.com/pysan3/pathlib.nvim/compare/v0.3.2...v0.4.0) (2024-01-30)


### Features

* **docs:** try to generate docs via sphinx ([4d8ca25](https://github.com/pysan3/pathlib.nvim/commit/4d8ca25575af9587294d3ae49ee6f47d463ceb0c))
* **watcher:** implement watcher to detect and invoke on file change ([de8a39d](https://github.com/pysan3/pathlib.nvim/commit/de8a39dc8daaff31ded1754a495f6258a5a90b72))


### Bug Fixes

* **base:** fix bugs and optimize performance ([8fb9050](https://github.com/pysan3/pathlib.nvim/commit/8fb90509d10730d62241e3ba31c84b1909888e16))
* **ci:** ensure pip reqs are installed ([227f409](https://github.com/pysan3/pathlib.nvim/commit/227f409e76bd53c9043e07ddf127dc9b7ecf667e))
* **ci:** fix typo ([4fdbc89](https://github.com/pysan3/pathlib.nvim/commit/4fdbc899d4388560a86dbc0961b8359fa446884e))
* **ci:** get sphinx executable paths ([0c72aa6](https://github.com/pysan3/pathlib.nvim/commit/0c72aa65df28ad0967106446e6b6c550ecfd272e))
* **ci:** ignore failed commands ([bfc23f3](https://github.com/pysan3/pathlib.nvim/commit/bfc23f3f3c5d62701a2d6b0c63cf61d814864720))
* **ci:** try to find executables installed with pip ([104f8a3](https://github.com/pysan3/pathlib.nvim/commit/104f8a386f6c73dd362a8e650543bcbaee66c609))
* **docs:** add link to docs in README ([f9f6b4c](https://github.com/pysan3/pathlib.nvim/commit/f9f6b4cda596aaff9accd9f72e674270f1f8842c))
* **docs:** save sphinx deps in requirement.txt ([70dcc2f](https://github.com/pysan3/pathlib.nvim/commit/70dcc2f19605ecf94a4554835adcf04120f63dda))
* **type:** public all fields ([41436f8](https://github.com/pysan3/pathlib.nvim/commit/41436f851f1ea7b681ece595ac93c43d7a4ba057))
* **types:** delete type annots on spec files ([4f47de8](https://github.com/pysan3/pathlib.nvim/commit/4f47de8db3e7a0af1ef0736d0bfb18b425a44edc))

## [0.3.2](https://github.com/pysan3/pathlib.nvim/compare/v0.3.1...v0.3.2) (2024-01-26)


### Bug Fixes

* **base:** update error_msg correctly ([37bdec1](https://github.com/pysan3/pathlib.nvim/commit/37bdec194f76e13178517e2acd9c6ad11f6f0d08))

## [0.3.1](https://github.com/pysan3/pathlib.nvim/compare/v0.3.0...v0.3.1) (2024-01-26)


### Bug Fixes

* **ci:** fix nvim-nio version ([d2965a5](https://github.com/pysan3/pathlib.nvim/commit/d2965a5225c7447b7b870a051dbf1607bda09de2))

## [0.3.0](https://github.com/pysan3/pathlib.nvim/compare/v0.2.0...v0.3.0) (2024-01-26)


### Features

* **base:** add `self:tostring()` and cache string result ([03be451](https://github.com/pysan3/pathlib.nvim/commit/03be451cb2139e449e952c5b38b9a6a853589056))
* **git:** implement method to fetch git status of files in a folder ([88d73b9](https://github.com/pysan3/pathlib.nvim/commit/88d73b9d2eea7cd9cf1d97da2d956a3f24bde5cc))
* **nuv:** integrate nvim-nio ([bcaeabd](https://github.com/pysan3/pathlib.nvim/commit/bcaeabddf29ba02e43fa665c92665c57579a43ad))
* **path:** add `Path.home` to get path to home dir ([d5e79b1](https://github.com/pysan3/pathlib.nvim/commit/d5e79b17b388496d5348ffbccf750f1f48365036))


### Bug Fixes

* **base:** refactor initialize function ([44163c0](https://github.com/pysan3/pathlib.nvim/commit/44163c04bf577a6cb61755cc9a6298b77a23b6a2))
* **ci:** do not release new tag to luarocks on pull_request ([4cf23f2](https://github.com/pysan3/pathlib.nvim/commit/4cf23f2b3068b578c9a976962b5b04ef9667d7fe))
* define `_init` for each path subclass ([c4708f0](https://github.com/pysan3/pathlib.nvim/commit/c4708f01837f67d828c92c75fcca1d2bbf4110d5))
* **git:** fix type annotations ([d2719a8](https://github.com/pysan3/pathlib.nvim/commit/d2719a801a3b584ab64214d74e4d4a6d4cbf1798))
* **list:** add option to ignore empty entries ([c4334dc](https://github.com/pysan3/pathlib.nvim/commit/c4334dc68d57858ed56dcc290d68e05c9ac57eda)), closes [#15](https://github.com/pysan3/pathlib.nvim/issues/15)
* **nuv:** add fallback for nio.current_task ([3d25ee2](https://github.com/pysan3/pathlib.nvim/commit/3d25ee272e263d2c8d5422d765a0bf41d7e84453))
* **pathlib:** fix inherit problem between base and posix ([5f0f368](https://github.com/pysan3/pathlib.nvim/commit/5f0f368b38958be5ae963e33a8f97dd0ff01289b))
* **type:** fix type annotations ([f982aba](https://github.com/pysan3/pathlib.nvim/commit/f982abae37fc4e94c439b7b9832ddc338b7e8152))
* **vim.fs:** use custom fs.normalize to support UNC paths ([07bcab8](https://github.com/pysan3/pathlib.nvim/commit/07bcab847f1d1222b6c40ba768d8b002421303bf))

## [0.2.0](https://github.com/pysan3/pathlib.nvim/compare/v0.1.7...v0.2.0) (2023-11-16)


### Features

* **base:** Implement posix methods ([#10](https://github.com/pysan3/pathlib.nvim/issues/10)) ([c32288e](https://github.com/pysan3/pathlib.nvim/commit/c32288e2d598e248d1dcb9f216be2b287ee52ab0))

## [0.1.7](https://github.com/pysan3/pathlib.nvim/compare/v0.1.6...v0.1.7) (2023-11-15)


### Bug Fixes

* **action:** delete unnecessary call to luarocks-tag-release ([3bde587](https://github.com/pysan3/pathlib.nvim/commit/3bde587e26726eec5363d84e702a3f27bf00e7bb))

## [0.1.6](https://github.com/pysan3/pathlib.nvim/compare/v0.1.5...v0.1.6) (2023-11-15)


### Bug Fixes

* **action:** use personal token for release-please ([3f7dc80](https://github.com/pysan3/pathlib.nvim/commit/3f7dc80c77b7e12917d6d296782fa9ce034cadc5))

## [0.1.5](https://github.com/pysan3/pathlib.nvim/compare/v0.1.4...v0.1.5) (2023-11-15)


### Bug Fixes

* **action:** luarocks-tag-release is not running ([14868f5](https://github.com/pysan3/pathlib.nvim/commit/14868f5205ee7f1ad22f1bcc0d921b7da63f7efb))

## [0.1.4](https://github.com/pysan3/pathlib.nvim/compare/v0.1.3...v0.1.4) (2023-11-15)


### Bug Fixes

* **action:** fix typo ([296aa23](https://github.com/pysan3/pathlib.nvim/commit/296aa238066b1bae34241cd7d800f2d07bffac83))

## [0.1.3](https://github.com/pysan3/pathlib.nvim/compare/v0.1.2...v0.1.3) (2023-11-15)


### Bug Fixes

* **action:** no dispatch ([01de854](https://github.com/pysan3/pathlib.nvim/commit/01de854704eabc57cad1b8ed4c112777f4d8ebfb))

## [0.1.2](https://github.com/pysan3/pathlib.nvim/compare/v0.1.1...v0.1.2) (2023-11-15)


### Bug Fixes

* **base:** no need to panic ([359122c](https://github.com/pysan3/pathlib.nvim/commit/359122c63e7573697050e4e82648eac3ca1e646c))

## [0.1.1](https://github.com/pysan3/pathlib.nvim/compare/v0.1.0...v0.1.1) (2023-11-15)


### Bug Fixes

* **action:** fix luarocks release action to invoke with new release ([1be7933](https://github.com/pysan3/pathlib.nvim/commit/1be79332f000ba44d9e9b0ed854d586f624b8537))
* **action:** fix typo ([5fdd072](https://github.com/pysan3/pathlib.nvim/commit/5fdd0725ff3ccea3874b8e48200a8b4a30c4d2d4))

## 0.1.0 (2023-11-15)


### Features

* **base:** add few more basic utilities for pathlib ([7e80585](https://github.com/pysan3/pathlib.nvim/commit/7e805851cbd2044a0152f0b6e21da986628dab1e))
* **base:** implement dunder methods ([0801104](https://github.com/pysan3/pathlib.nvim/commit/08011047e09b68da064099977aea238741a57a48))
* **base:** implement plugin template ([879d350](https://github.com/pysan3/pathlib.nvim/commit/879d3509a717f8e24478642e58f13baf0ebd5683))


### Bug Fixes

* **ci:** add neodev to rtp ([3434639](https://github.com/pysan3/pathlib.nvim/commit/3434639d5f1e4f151f92b5002e6f3efd1f26ad0c))
* **ci:** install neodev before type checking ([752630f](https://github.com/pysan3/pathlib.nvim/commit/752630f98d8b791524a61e05f62d31680df6efee))
* **ci:** specify absolute path for libraries ([dda83f7](https://github.com/pysan3/pathlib.nvim/commit/dda83f792959733325ea2a1c977a5a7501f6e902))
* **ci:** specify correct path to config file ([320b29a](https://github.com/pysan3/pathlib.nvim/commit/320b29a05b2bf98759e096570c844b599124d31b))
* **ci:** specify path to luarc configpath ([7a10cb5](https://github.com/pysan3/pathlib.nvim/commit/7a10cb53adf0905523bf8674fcf519cc228f62f0))


### Miscellaneous Chores

* release unstable version to test luarocks ([094be4b](https://github.com/pysan3/pathlib.nvim/commit/094be4b695baae127986f7c76936b5514ca2de32))
