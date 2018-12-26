#include "StdAfx.h"
#include "Nodes.h"

using namespace std;

Nodes::Nodes(const string& filename)
{
	std::ifstream ifs (filename.c_str(), std::ifstream::in);
	
	node_x.resize(0);
	node_y.resize(0);
	node_p.resize(0);

	//CityId,X,Y,not_prime

    //read header
	string s;
	getline( ifs, s );

	while (ifs)
	{
		
		if (!getline( ifs, s )) break;
		
		istringstream ss( s );
		vector <string> record;
		while (ss)
		{
			string s;
			if (!getline( ss, s, ',' )) break;
			record.push_back( s );
		}

		int city_id = atoi(record[0].c_str());

		if(city_id!=node_x.size())
			throw std::exception("wrong city id");

		if(record.size()!=4)
			throw std::exception("wrong record size");

		node_x.push_back(atof(record[1].c_str()));
		node_y.push_back(atof(record[2].c_str()));
		node_p.push_back(atoi(record[3].c_str()));
	}

	ifs.close();
}

double Nodes::tour_distance(const std::vector<int>& tour) const
{
	double total_dist = 0.0;

	#pragma omp parallel for reduction(+:total_dist)
	for(int i=1; i<tour.size(); i++)
	{
		int prev_id = tour[i-1];
		int curr_id = tour[i  ];

		double dx = node_x[curr_id] - node_x[prev_id];
		double dy = node_y[curr_id] - node_y[prev_id];

		double dist = sqrt(dx * dx + dy * dy);

		if( i % 10 == 0 && node_p[prev_id] == 1)
		{
			dist = 1.1 * dist;
		}

		total_dist += dist;
	}
	return total_dist;
}

bool Nodes::check_tour(const std::vector<int>& tour) const
{
	std::vector<int> my_tour = tour;

	if(my_tour.size()<2 || my_tour[0] != 0 ||  my_tour[my_tour.size()-1] != 0)
		return false;
		
	std::sort (my_tour.begin(), my_tour.end());    

	for(int i=2; i<my_tour.size(); i++)
	{
		if(my_tour[i] != (i-1))
			return false;
	}

	return true;
}


double Nodes::tour_distance(const std::vector<int>& tour, int start_index, int n_tour_size) const
{
	double total_dist = 0.0;
	
	#pragma omp parallel for reduction(+:total_dist)
	for(int j=1; j<n_tour_size; j++)
	{
		int i = start_index + j;

		int prev_id = tour[i-1];
		int curr_id = tour[i  ];

		double dx = node_x[curr_id] - node_x[prev_id];
		double dy = node_y[curr_id] - node_y[prev_id];

		double dist = sqrt(dx * dx + dy * dy);

		if( j % 10 == 0 && node_p[prev_id] == 1)
		{
			dist = 1.1 * dist;
		}

		total_dist += dist;
	}
	return total_dist;
}


double Nodes::segment_distance(const std::vector<int>& tour, int s_index, int e_index, int n_tour_size) const
{	
	double total_dist = 0.0;

	//#pragma omp parallel for reduction(+:total_dist)
	for(int i=s_index+1; i<=e_index; i++)
	{
		int prev_id = tour[i-1];
		int curr_id = tour[i  ];

		double dx = node_x[curr_id] - node_x[prev_id];
		double dy = node_y[curr_id] - node_y[prev_id];

		double dist = sqrt(dx * dx + dy * dy);

		if( i % 10 == 0 && node_p[prev_id] == 1)
		{
			dist = 1.1 * dist;
		}

		total_dist += dist;
	}
	return total_dist;
}

Nodes::~Nodes(void)
{
}
