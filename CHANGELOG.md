# Changelog

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
