#pragma once
class Nodes
{
public:
	std::vector<double> node_x;
	std::vector<double> node_y;
	std::vector<int> node_p;

	Nodes(const std::string& filename);

	double tour_distance(const std::vector<int>& tour) const;
	double tour_distance(const std::vector<int>& tour, int start_index, int n_tour_size) const;

	virtual ~Nodes(void);
};
