## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Functions for cleaning the raw data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Data cleaning -----------------------------------------------------------

#= 
Function to create matches for parents, parents-in-law, or grandparents
within each household with multiple pairs
=#
function create_parent_matches(sdf)
    pernums = sort(sdf.pernum)
    num_pairs = div(length(pernums), 2)
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        # Pair pernums[2i - 1] with pernums[2i]
        gp1 = pernums[2i-1]
        gp2 = pernums[2i]
        # Assign sploc for both parents
        push!(matches, (hhid=hhid, pernum=gp1, sploc=gp2))
        push!(matches, (hhid=hhid, pernum=gp2, sploc=gp1))
    end
    # If there's an unmatched grandparent (odd number), their 'sploc' remains missing
    return matches
end

#= 
Function to create matches of children and children-in-law
within each household with multiple pairs
=#
function create_children_matches(sdf)
    # Extract `pernum` of children and children-in-law
    children = sort(sdf[sdf.role.=="child", :pernum])
    children_in_law = sort(sdf[sdf.role.=="child_in_law", :pernum])
    num_pairs = min(length(children), length(children_in_law))
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        child_pernum = children[i]
        child_in_law_pernum = children_in_law[i]
        # Assign sploc for child
        push!(matches, (hhid=hhid, pernum=child_pernum, sploc=child_in_law_pernum))
        # Assign sploc for child-in-law
        push!(matches, (hhid=hhid, pernum=child_in_law_pernum, sploc=child_pernum))
    end
    return matches
end