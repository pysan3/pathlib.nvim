# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'pathlib.nvim'
copyright = '2023, pysan3'
author = 'pysan3'
release = '0.4.1' # x-release-please-version

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinxcontrib.luadomain',
    'sphinx_lua',
    'myst_parser',
]

templates_path = ['_templates']
source_suffix = ['.rst', '.md']
exclude_patterns = [
    '_build',
    'Thumbs.db',
    '.DS_Store',
    'lua_modules',
]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'pydata_sphinx_theme'
html_theme_options = {
    'navigation_with_keys': False,
}
# html_theme = 'press'
html_static_path = ['_static']


# Available options and default values
lua_source_path = ["./lua/pathlib"]
lua_source_encoding = 'utf8'
lua_source_comment_prefix = '---'
lua_source_use_emmy_lua_syntax = True
lua_source_private_prefix = '_'
