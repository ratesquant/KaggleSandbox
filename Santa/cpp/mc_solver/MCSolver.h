#pragma once

class Nodes;

class MCSolver
{
	const Nodes& m_nodes;
public:
	MCSolver(const Nodes& nodes):m_nodes(nodes){};

	const std::vector<int> run_iterations(const std::vector<int>& tour, int maxit, int p_size) const;

	virtual ~MCSolver(void);
};

