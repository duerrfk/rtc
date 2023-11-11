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
# Frame-based scheduling with splitting using max-flow algorithm.
##

### Given:
# Periodic tasks with (period=deadline, execution time) or (period, execution time, deadline):
# T1 = (4,1)
# T2 = (5,2,7)
# T3 = (20,5)
#
# Hyperperiod: 20
#
# Frame length: 4, i.e., 5 frames

t1ExecTime = 1
t2ExecTime = 2
t3ExecTime = 5

framelength = 4

m = Model(solver=GurobiSolver(Presolve=0))

### For each source-to-job edge, define a variable.

@variable(m, xSrcJ11)
@variable(m, xSrcJ12)
@variable(m, xSrcJ13)
@variable(m, xSrcJ14)
@variable(m, xSrcJ15)

@variable(m, xSrcJ21)
@variable(m, xSrcJ22)
@variable(m, xSrcJ23)
@variable(m, xSrcJ24)

@variable(m, xSrcJ31)

### For each job-to-frame edge, define a variable.

@variable(m, xJ11F1)
@variable(m, xJ12F2)
@variable(m, xJ13F3)
@variable(m, xJ14F4)
@variable(m, xJ15F5)

@variable(m, xJ21F1)
@variable(m, xJ22F3)
@variable(m, xJ23F4)
@variable(m, xJ24F5)

@variable(m, xJ31F1)
@variable(m, xJ31F2)
@variable(m, xJ31F3)
@variable(m, xJ31F4)
@variable(m, xJ31F5)

### For each frame-to-sink edge define a variable.

@variable(m, xF1Sink)
@variable(m, xF2Sink)
@variable(m, xF3Sink)
@variable(m, xF4Sink)
@variable(m, xF5Sink)

### Constraints: flow conservation for each job node. 

@constraint(m, xSrcJ11 == xJ11F1)
@constraint(m, xSrcJ12 == xJ12F2)
@constraint(m, xSrcJ13 == xJ13F3)
@constraint(m, xSrcJ14 == xJ14F4)
@constraint(m, xSrcJ15 == xJ15F5)

@constraint(m, xSrcJ21 == xJ21F1)
@constraint(m, xSrcJ22 == xJ22F3)
@constraint(m, xSrcJ23 == xJ23F4)
@constraint(m, xSrcJ24 == xJ24F5)

@constraint(m, xSrcJ31 == xJ31F1 + xJ31F2 + xJ31F3 + xJ31F4 + xJ31F5)

### Constraints: flow conservation for each frame node.

@constraint(m, xJ11F1 + xJ21F1 + xJ31F1 == xF1Sink)
@constraint(m, xJ12F2 + xJ31F2 == xF2Sink)
@constraint(m, xJ13F3 + xJ22F3 + xJ31F3 == xF3Sink)
@constraint(m, xJ14F4 + xJ23F4 + xJ31F4 == xF4Sink)
@constraint(m, xJ15F5 + xJ24F5 + xJ31F5 == xF5Sink)

### Constraints: for each frame node, outgoing flow must be less-equal than frame length.
# Due to the balance constraints on frame nodes, this automatically restricts the sum
# of incoming flows into a frame node.
@constraint(m, xF1Sink <= framelength)
@constraint(m, xF2Sink <= framelength)
@constraint(m, xF3Sink <= framelength)
@constraint(m, xF4Sink <= framelength)
@constraint(m, xF5Sink <= framelength)

### Constraints: for each job node, incoming flow must be less-equal than job executing time.
# Due to the balance constraints on job nodes, this automatically restricts the sum of outgoing flows from
# a job node.

@constraint(m, xSrcJ11 <= t1ExecTime)
@constraint(m, xSrcJ12 <= t1ExecTime)
@constraint(m, xSrcJ13 <= t1ExecTime)
@constraint(m, xSrcJ14 <= t1ExecTime)
@constraint(m, xSrcJ15 <= t1ExecTime)

@constraint(m, xSrcJ21 <= t2ExecTime)
@constraint(m, xSrcJ22 <= t2ExecTime)
@constraint(m, xSrcJ23 <= t2ExecTime)
@constraint(m, xSrcJ24 <= t2ExecTime)

@constraint(m, xSrcJ31 <= t3ExecTime)

### All flows positive.

@constraint(m, xSrcJ11 >= 0)
@constraint(m, xSrcJ12 >= 0)
@constraint(m, xSrcJ13 >= 0)
@constraint(m, xSrcJ14 >= 0)
@constraint(m, xSrcJ15 >= 0)

@constraint(m, xSrcJ21 >= 0)
@constraint(m, xSrcJ22 >= 0)
@constraint(m, xSrcJ23 >= 0)
@constraint(m, xSrcJ24 >= 0)

@constraint(m, xSrcJ31 >= 0)

@constraint(m, xF1Sink >= 0)
@constraint(m, xF2Sink >= 0)
@constraint(m, xF3Sink >= 0)
@constraint(m, xF4Sink >= 0)
@constraint(m, xF5Sink >= 0)

@constraint(m, xJ11F1 >= 0)
@constraint(m, xJ12F2 >= 0)
@constraint(m, xJ13F3 >= 0)
@constraint(m, xJ14F4 >= 0)
@constraint(m, xJ15F5 >= 0)
@constraint(m, xJ21F1 >= 0)
@constraint(m, xJ22F3 >= 0)
@constraint(m, xJ23F4 >= 0)
@constraint(m, xJ24F5 >= 0)

@constraint(m, xJ31F1 >= 0)
@constraint(m, xJ31F2 >= 0)
@constraint(m, xJ31F3 >= 0)
@constraint(m, xJ31F4 >= 0)
@constraint(m, xJ31F5 >= 0)

### Objective: maximize flow into sink.

@objective(m, Max, xF1Sink + xF2Sink + xF3Sink + xF4Sink + xF5Sink)

solve(m)

### Print splitting of flows

println("J11F1 = " * string(getvalue(xJ11F1)))
println("J12F2 = " * string(getvalue(xJ12F2)))
println("J13F3 = " * string(getvalue(xJ13F3)))
println("J14F4 = " * string(getvalue(xJ14F4)))
println("J15F5 = " * string(getvalue(xJ15F5)))

println("J21F1 = " * string(getvalue(xJ21F1)))
println("J22F3 = " * string(getvalue(xJ22F3)))
println("J23F4 = " * string(getvalue(xJ23F4)))
println("J24F5 = " * string(getvalue(xJ24F5)))

println("J31F1 = " * string(getvalue(xJ31F1)))
println("J31F2 = " * string(getvalue(xJ31F2)))
println("J31F3 = " * string(getvalue(xJ31F3)))
println("J31F4 = " * string(getvalue(xJ31F4)))
println("J31F5 = " * string(getvalue(xJ31F5)))