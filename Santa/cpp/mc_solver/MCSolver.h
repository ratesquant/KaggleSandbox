#pragma once

#include "sfmt/SFMT.h"

class Nodes;

class MCSolver
{
	const Nodes& m_nodes;
	sfmt_t m_sfmt;

public:
	MCSolver(const Nodes& nodes);

	const std::vector<int> run_iterations(const std::vector<int>& tour, int maxit, int p_size);

	virtual ~MCSolver(void);

private:
	void mutate_tour(const std::vector<int>& tour, int start_index, int n_tour_size, std::vector<int>& next_tour);
};

