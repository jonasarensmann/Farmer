# Farmer

A Package manager for [Lune](https://github.com/lune-org/lune).
It is a simple package manager that allows you to install and manage packages for Lune.
Packages are called "Crops" in Farmer. They are stored in the `crops` directory.

## Usage

```bash
Commands:
    init  <name>    Initialize a new project
    add <crop>      Add a new dependency
    remove <crop>   Remove a dependency
    bundle <output> Bundle a project to a single file (beta)
    install         Install dependencies
    list            List dependencies
    upload          Upload a package
    help            Display a help message
```

## The Registry

The Registry is a place where you can upload your crops to share them with others. You can also download crops from the Registry. The Registry is located at `https://farmer.jonas-arensmann.com`.

## Docs

The docs are located at `https://farmer.jonas-arensmann.com/docs`.

## Installation

```bash
git clone https://github.com/jonasarensmann/farmer.git

cd Farmer

lune run src/main bundle bundle.luau

lune build bundle.luau -o farmer

# Now you can run the farmer executable
./farmer
```

(Optional) Add the `farmer` executable to your PATH.

```bash
sudo cp farmer /usr/local/bin
```

## License

Farmer is licensed under the MIT License.
