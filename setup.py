from setuptools import setup, Extension
from Cython.Build import cythonize
"""
ext_modules=[
    Extension("spire",       ["cy_files/server.pyx"]),
    Extension("client",         ["client.pyx"]),
]
"""
setup(
    # ext_modules=cythonize("cy_files/server.pyx"),
    # ext_modules = ext_modules,
    ext_modules=cythonize(["cy_files/*.pyx"]),
)
