/**
 * Copyright 2023 University of Stuttgart 
 * Author: Frank Duerr (frank.duerr@ipvs.uni-stuttgart.de) 
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); 
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at                         
 *                                                                 
 * http://www.apache.org/licenses/LICENSE-2.0                      
 *                                                                  
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,  
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and     
 * limitations under the License.                                          
 */

#include <ilcp/cp.h>
#include <map>

/**
 * Clock-driven scheduling.
 * Given a set of periodic tasks. Find start times for each job.
 */

/**
 * Given:
 * 
 * Periodic tasks (period/deadline, execution time):
 * 
 * T1 = (6,2)
 * T2 = (12,3)
 * T3 = (18,4)
 * 
 * Hyperperiod: 36
 */

const unsigned int nbJobs = 10;

// Set of jobs, e.g. J12 is second job of first task.
enum jobs {J11, J12, J13, J14, J15, J21, J22, J23, J31, J32};

// Job names for printing
std::map<enum jobs, std::string> jobnames {
	{J11, "J11"},
	{J12, "J12"},
	{J13, "J13"},
	{J14, "J14"},
	{J15, "J15"},
	{J21, "J21"},
	{J22, "J22"},
	{J23, "J23"},
	{J31, "J31"},
	{J32, "J32"}
};

// Release times for each job
std::map<enum jobs, int> releasetimes {
	{J11, 0},
	{J12, 6},
	{J13, 12},
	{J14, 18},
	{J15, 24},
	{J21, 0},
	{J22, 12},
	{J23, 24},
	{J31, 0},
	{J32, 18}
};

// Deadlines for each job
std::map<enum jobs, int> deadlines {
	{J11, 0+6},
	{J12, 6+6},
	{J13, 12+6},
	{J14, 18+6},
	{J15, 24+6},
	{J21, 0+12},
	{J22, 12+12},
	{J23, 24+12},
	{J31, 0+18},
	{J32, 18+18}
};

// Execution times for each job
std::map<enum jobs, int> executiontimes {
	{J11, 2},
	{J12, 2},
	{J13, 2},
	{J14, 2},
	{J15, 2},
	{J21, 3},
	{J22, 3},
	{J23, 3},
	{J31, 4},
	{J32, 4}
};

int main(int argc, char *argv[])
{
	IloEnv env;

	try {
		IloModel model(env);

		// List of jobs. Each job is an interval variable denoting the time during which the job is executed. 
		IloIntervalVarArray jobexecintervals(env, nbJobs);

		for (unsigned int i = 0; i < nbJobs; i++) {
			// One interval variable per job.
			// The start of the interval is the start time of the job.
			// The end of the interval is the completion time of the job.
			// Here, we specify only the job duration (execution time).
			// Start time and end time are calculated (solution).
			IloIntervalVar ivar(env, executiontimes[(enum jobs) (i)]);
			jobexecintervals[i] = ivar;

			// Constraints: start time of jobs must be at or after release time.
			model.add(IloStartOf(ivar) >= releasetimes[(enum jobs) (i)]);
			
			// Constraints: end time of jobs must be before or at deadline.
			model.add(IloEndOf(ivar) <= deadlines[(enum jobs) (i)]);

		}

		// Constraints: job executions must not overlap in time. 
		model.add(IloNoOverlap(env, jobexecintervals));
		      
		IloCP cp(model);
		if (cp.solve()) {
			std::cout << "Job start times:" << std::endl;
			for (unsigned int i = 0; i < nbJobs; i++) {
				std::cout << jobnames[(enum jobs) (i)] << " = " << cp.getValue(IloStartOf(jobexecintervals[i])) << std::endl;				
			}
		}
		else {
			cp.out() << "Infeasible."  << std::endl;
		}
		    
		cp.end();
	} catch (IloException &ex) {
		env.out() << "Caught: " << ex << std::endl;
	}
	env.end();
	
	return 0;
}
