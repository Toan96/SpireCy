from setuptools import setup, Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext

"""
ext_modules=[
    Extension("spire",       ["cy_files/server.pyx"]),
    Extension("client",         ["client.pyx"]),
]

setup(
    # ext_modules=cythonize("cy_files/server.pyx"),
    # ext_modules = ext_modules,
    ext_modules=cythonize(["cy_files/*.pyx"]),
)
"""

ext_modules = cythonize([Extension("client", ["cy_files/client.pyx", 'c_files/utils.c', 'c_files/factorizations.c']),
                         Extension("server", ["cy_files/server.pyx"]) ])


setup(
  name = 'SpireCy',
  cmdclass = {'build_ext': build_ext},
  ext_modules = ext_modules
)