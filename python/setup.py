"""Setup configuration for AWS Glue Schema Registry Python Client."""

from setuptools import setup, find_packages
from pathlib import Path

# Read the README file
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

setup(
    name="glue-schema-registry",
    version="1.0.33",
    author="AWS Glue Schema Registry",
    description="Python client for AWS Glue Schema Registry",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/aws-glue-schema-registry/python",
    packages=find_packages(exclude=["tests", "tests.*"]),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Distributed Computing",
    ],
    python_requires=">=3.8",
    install_requires=[
        "boto3>=1.28.0",
        "fastavro>=1.8.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "build>=0.10.0",
            "wheel>=0.40.0",
        ],
    },
    include_package_data=True,
    zip_safe=False,
)

