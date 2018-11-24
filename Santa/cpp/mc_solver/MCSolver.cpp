#include "StdAfx.h"
#include "MCSolver.h"

const std::vector<int> MCSolver::run_iterations(const std::vector<int>& tour, int maxit, int p_size) const
{
	int n_best = std::max(1, int(0.05 * p_size));
	int n_tour_size = tour.size();

	std::vector<double> scores(p_size);

	std::vector<int> tours(p_size * tour.size());
	std::vector<int> next_tours(p_size * n_tour_size);


	for(int i=0; i<maxit; i++)
	{	
		std::cout<<"it: "<<i<<std::endl;
		//mutate all, replace "n_best" worst with unchanged "n_best" tours from previous iteration		

	}

	return tour;
}


MCSolver::~MCSolver(void)
{
}
