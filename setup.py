import os.path
import sys

from setuptools import setup
from textwrap import dedent

def get_version():
    cur_dir = os.path.dirname(__file__)
    init_path = os.path.join(cur_dir, "edbpotdeploy", "__init__.py")

    with open(init_path) as f:
        for line in f:
            if line.startswith("__version__"):
                return line.split('"')[1]
    raise Exception("Version information not found in %s" % init_path)

def get_long_description():
    cur_dir = os.path.dirname(__file__)
    with open(os.path.join(cur_dir, "README.md")) as f:
        return f.read()

setup(
    name="edb-pot",
    version=get_version(),
    author="EDB",
    author_email="edb-devops@enterprisedb.com",
    scripts=["edb-pot"],
    packages=["edbpotdeploy", "edbpotdeploy.spec"],
    url="https://github.com/EnterpriseDB/postgres-deployment/",
    license="BSD",
    description=dedent("""
Postgres Deployment Scripts are an easy way to deploy PostgreSQL, EDB Postgres
Advanced Server, and EDB Tools in the Cloud.
    """),
    long_description=get_long_description(),
    long_description_content_type="text/markdown",
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "License :: OSI Approved :: BSD License",
        "Programming Language :: Python :: 2.7",
        "Programming Language :: Python :: 3",
        "Topic :: Database",
    ],
    keywords="postgresql edb epas cli deploy cloud aws azure gcloud",
    python_requires=">=2.7",
    install_requires=["argcomplete"],
    extras_require={},
    data_files=[
        (
            'share/edb-pot/scripts',
            [
                'scripts/install_requirements_linux_x64.sh',
                'scripts/install_requirements_darwin_x64.sh',
            ]
        )
    ],
    package_data={
        'edbpotdeploy': [
            'data/ansible/*.yml',
            'data/ansible/*/*/*/*.yml',
            'data/ansible/*/*/*/*.template',
            'data/terraform/*/*.tf.template',
            'data/terraform/*/*.tf',
            'data/terraform/*/*/*.tf',
            'data/terraform/*/*/*.sh',
            'data/terraform/*/*/*/*.tf',
            'data/terraform/*/*/*/*.sh',
            'data/terraform/*/*/*/*/*.tf',
            'data/terraform/*/*/*/*/*.sh',
        ]
    }
)
