##
# Copyright 2023 University of Stuttgart 
# Author: Frank Duerr (frank.duerr@ipvs.uni-stuttgart.de) 
#
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at                         
#                                                                 
# http://www.apache.org/licenses/LICENSE-2.0                      
#                                                                 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,  
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and     
# limitations under the License.                                          
##

using JuMP
using Gurobi

##
# Clock-driven scheduling:
# Given a set of periodic tasks, find start times for each job. 
##

## Given:
# Periodic tasks (period/deadline, execution time):
# T1 = (6,2)
# T2 = (12,3)
# T3 = (18,4)
#
# Hyperperiod: 36

### Set of jobs, e.g. J12 is second job of first task.
jobs = [:J11, :J12, :J13, :J14, :J15, :J16, :J21, :J22, :J23, :J31, :J32]

### Release times for each job
releasetimes = Dict(
    :J11 => 0,
    :J12 => 6,
    :J13 => 12,
    :J14 => 18,
    :J15 => 24,
    :J16 => 30,
    :J21 => 0,
    :J22 => 12,
    :J23 => 24,
    :J31 => 0,
    :J32 => 18,
)

### Deadlines for each job
deadlines = Dict(
    :J11 => 0+6,
    :J12 => 6+6,
    :J13 => 12+6,
    :J14 => 18+6,
    :J15 => 24+6,
    :J16 => 30+6,
    :J21 => 0+12,
    :J22 => 12+12,
    :J23 => 24+12,
    :J31 => 0+18,
    :J32 => 18+18,
)

### Execution times for each job
executiontimes = Dict(
    :J11 => 2,
    :J12 => 2,
    :J13 => 2,
    :J14 => 2,
    :J15 => 2,
    :J16 => 2,
    :J21 => 3,
    :J22 => 3,
    :J23 => 3,
    :J31 => 4,
    :J32 => 4,
)

m = Model(solver=GurobiSolver(Presolve=0))

# Variables for job start times.
@variable(m, x[j=jobs])

# Constraint: start time of each job must be after its release time.
for job in jobs
    @constraint(m, x[job] >= releasetimes[job])
end

# Constraint: end of job must be before deadline
for job in jobs
    @constraint(m, x[job]+executiontimes[job] <= deadlines[job])
end

# Constraint: for each pair (J1,J2) of different jobs, their execution
# must not overlap in time. This can be expressed as a disjunction (OR):
#
# J1 after J2: start of J1 >= start of J2 + execution time of J2
#   OR
# J1 before J2: start of J2 >= start of J1 + execution time of J1
# 
# Such disjunctions are harder to express in ILPs. We can use the Big-M method
# using a binary helper variable and a sufficiently large constant BigM.
@variable(m, helper[job1=jobs,job2=jobs], Bin)
BigM = 2*36 # left-hand side is always smaller than this value.
for j1 in jobs
    for j2 in jobs
        if j1 != j2
            @constraint(m, x[j2] + executiontimes[j2] - x[j1] <= BigM*helper[j1,j2])
	    @constraint(m, x[j1] + executiontimes[j1] - x[j2] <= BigM*(1-helper[j1,j2]))		    
        end
    end
end

solve(m)

sol = getvalue(x)
for job in jobs
    println(string(job) * " -> " * string(sol[job]));
end