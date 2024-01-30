.. pathlib.nvim documentation master file, created by
   sphinx-quickstart on Tue Jan 30 19:57:03 2024.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

================================
🐍 `pathlib.nvim <README.html>`_
================================

**OS independent, ultimate solution to path handling in neovim.**
=> Go to `README <README.html>`_.

This plugin aims to decrease the difficulties of path management across mutliple OSs in neovim.
The plugin API is heavily inspired by Python's `pathlib.Path` with tweaks to fit neovim usage.
It is mainly used in `neo-tree.nvim <https://github.com/nvim-neo-tree/neo-tree.nvim>`_
but it is very simple and portable to be used in any plugin.

Pathlib Module Reference
========================

* :lua:class:`PathlibPath`
* :lua:class:`PathlibPosixPath`
* :lua:class:`PathlibWindowsPath`
* List by :ref:`genindex`
* :ref:`search`

TOC
---

.. toctree::
   :numbered:
   :maxdepth: 1
   :glob:

   README
   doc/*

