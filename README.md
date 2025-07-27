# OMLx_install
Install script and setup for OM Lx ROME/ROCK

Step 1: Generate a list of installed packages:

- For this step, we want to get a list of user-installed packages. We'll ultimately refine this list by removing any
libraries/dependencies that will be automatically installed by the dnf package manager.
- To start, run the command: dnf history userinstalled >> ~/packages.txt
This will generate a list of user-installed packages and will create a file called packages.txt in your HOME directory

Step 2: Refine the list of installed packages:

- From here, we want to run the "analyze_packages.sh" script to look through your packages.txt file. This script will
sort through the list, will remove likely dependencies, and will generate a new file "packages_optimized.txt" that lists
Plasma Desktop components and user-installed applications.

