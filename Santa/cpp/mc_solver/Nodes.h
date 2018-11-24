#pragma once
class Nodes
{
public:
	std::vector<double> node_x;
	std::vector<double> node_y;
	std::vector<int> node_p;

	Nodes(const std::string& filename);

	double tour_distance(const std::vector<int>& tour);

	virtual ~Nodes(void);
};
