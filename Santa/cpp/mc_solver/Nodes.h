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
	double tour_distance_noise(const std::vector<int>& tour, const std::vector<double>& sigma_x, const std::vector<double>& sigma_y) const;

	double segment_distance(const std::vector<int>& tour, int s_index, int e_index) const;

	bool check_tour(const std::vector<int>& tour) const;

	virtual ~Nodes(void);
};
