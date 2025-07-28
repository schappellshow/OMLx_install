# OMLx_install
Install script and setup for OM Lx ROME/ROCK

Clone this repo to your system first.
git clone https://github.com/schappellshow/OMLx_install.git

cd OMLx_install

Step 1: Generate a list of installed packages:

- For this step, we want to get a list of installed packages. We'll ultimately refine this list by removing any
libraries/dependencies that will be automatically installed by the dnf package manager.
- To start, run the command: dnf list installed >> packages.txt
This will generate a list of installed packages and will create a file called packages.txt in your HOME directory

Step 2: Refine the list of installed packages:

- From here, we want to run the "analyze_packages.sh" script to compare your your packages.txt file to a list of packages from a clean OMLx-ROME install.
This script will sort through both lists, and will remove any pacakages that are present in both lists.
The result will be a file, packages_custom.txt that will contain only the packages and dependencies that you've installed.

Look through this list of packages and remove any that you do not want to have in a fresh install.

Step 3: 

