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
# Frame-based scheduling with optimization objective:
# Find optimal assignment of jobs to frames with least slack time objective.
##

### Given:
# Periodic tasks (period/deadline, execution time):
# T1 = (20,5)
# T2 = (25,9)
# T3 = (100,5)
# T4 = (100,10)
#
# Hyperperiod: 100
#
# Framesize: 10

### Set of jobs, e.g. J12 is second job of first task.
jobs = [:J11, :J12, :J13, :J14, :J15, :J21, :J22, :J23, :J24, :J31, :J41]

### 10 Frames of framesize 10
frames = [:F1, :F2, :F3, :F4, :F5, :F6, :F7, :F8, :F9, :F10]
framesize = 10
framestarttimes = Dict(
    :F1 => 0,
    :F2 => 10,
    :F3 => 20,
    :F4 => 30,
    :F5 => 40,
    :F6 => 50,
    :F7 => 60,
    :F8 => 70,
    :F9 => 80,
    :F10 => 90,
)

### Release times for each job
releasetimes = Dict(
    :J11 => 0,
    :J12 => 20,
    :J13 => 40,
    :J14 => 60,
    :J15 => 80,
    :J21 => 0,
    :J22 => 25,
    :J23 => 50,
    :J24 => 75,
    :J31 => 0,
    :J41 => 0,
)

### Deadlines for each job
deadlines = Dict(
    :J11 => 0+20,
    :J12 => 20+20,
    :J13 => 40+20,
    :J14 => 60+20,
    :J15 => 80+20,
    :J21 => 0+25,
    :J22 => 25+25,
    :J23 => 50+25,
    :J24 => 75+25,
    :J31 => 0+100,
    :J41 => 0+100,
)

### Execution times for each job
executiontimes = Dict(
    :J11 => 5,
    :J12 => 5,
    :J13 => 5,
    :J14 => 5,
    :J15 => 5,
    :J21 => 9,
    :J22 => 9,
    :J23 => 9,
    :J24 => 9,
    :J31 => 5,
    :J41 => 10,
)

### Set of eligible frames for each job:
# frame start must be >= job release time
# frame end must be <= job deadline, i.e., release time + execution time 
eligibleframes = Dict()
for frame in frames
    fstart = framestarttimes[frame]
    fend = fstart+framesize
    for job in jobs
        releasetime = releasetimes[job]
	deadline = deadlines[job]
        if fstart >= releasetime && deadline >= fend
            eligibleframes[job,frame] = 1
	else
            eligibleframes[job,frame] = -1
	end
    end
end    

m = Model(solver=GurobiSolver(Presolve=0))

# Binary variables for frames assignment.
@variable(m, x[j=jobs, f=frames], Bin)

# Constraint: assign exactly one frame to each job.
for job in jobs
    @constraint(m, sum(x[job,frame] for frame in frames) == 1)
end

# Constraint: only assign jobs to eligible frames
for job in jobs
    for frame in frames
        @constraint(m, eligibleframes[job,frame]*x[job,frame] >= 0)
    end
end

# Constraint: do not exceed capacity of frames
for frame in frames
    @constraint(m, sum(executiontimes[job]*x[job,frame] for job in jobs) <= framesize)
end

# Objective: maximize least slack time (idle time) of frames.
# Define a variable for the least slack time and a constraint that the least slack time
# must be smaller than the slack time of any frame.
# Maximizing this variable will make sure that the least slack time is actually the *least*
# possible value.
@variable(m, leastslacktime)
for frame in frames
    @constraint(m, framesize-sum(executiontimes[job]*x[job,frame] for job in jobs) >= leastslacktime)
end

@objective(m, Max, leastslacktime)

solve(m)

sol = getvalue(x)
for job in jobs
    for frame in frames
        if sol[job,frame] == 1
            println(string(job) * " -> " * string(frame));
        end
    end
end