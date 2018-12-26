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
	const std::vector<int> random_search(const std::vector<int>& tour, int method, int maxit, int span);

	virtual ~MCSolver(void);

private:
	void mutate_tour(const std::vector<int>& tour, int start_index, int n_tour_size, std::vector<int>& next_tour);
	void mutate_tour_flip(const std::vector<int>& tour, int start_index, int n_tour_size, std::vector<int>& next_tour);

	void get_random_indexes(int n, int span, int& index_1, int& index_2);
	void get_random_indexes(int n, int& s_index, int& e_index);
};

