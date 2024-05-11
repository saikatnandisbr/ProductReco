# submodules

# includes
# 1. include submodule entry file
# 2. import submodule into paranet module
# 3. export from parent module, if desired, submodule objects
include("submodules/pr_coll_filtering/PRCollFiltering.jl")              # 1. submodule PRCollFiltering - collaborative filtering
using .PRCollFiltering                                                  # 2. import submodule into parent
